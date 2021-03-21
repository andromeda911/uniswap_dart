import 'package:decimal/decimal.dart';

import '../constants.dart';
import './Pair.dart';
import './Route.dart';
import './currency/Currency.dart';
import './currency/CurrencyAmount.dart';
import './token/Token.dart';
import './token/TokenAmount.dart';
import 'package:web3dart/web3dart.dart';

import 'Price.dart';

enum TradeType { EXACT_INPUT, EXACT_OUTPUT }

TokenAmount wrappedAmount(CurrencyAmount currencyAmount, int chainId) {
  if (currencyAmount is TokenAmount) return currencyAmount;
  if (currencyAmount.currency == ETHER) return TokenAmount(WETH9[chainId], currencyAmount.value);
  assert(false);
}

Token wrappedCurrency(Currency currency, int chainId) {
  if (currency is Token) return currency;
  if (currency == ETHER) return WETH9[chainId];
  assert(false);
}

Decimal computePriceImpact(Price midPrice, CurrencyAmount inputAmount, CurrencyAmount outputAmount) {
  var exactQuote = midPrice.price * Decimal.parse('${inputAmount.value.getInWei}');
  var slippage = (exactQuote - Decimal.parse('${outputAmount.value.getInWei}') / exactQuote);
  return slippage;
}

class Trade {
  Route route;
  TradeType tradeType;
  CurrencyAmount inputAmount;
  CurrencyAmount outputAmount;
  Price executionPrice;
  Price nextMidPrice;
  Decimal priceImpact;
  Trade(
    this.route,
    CurrencyAmount amount,
    this.tradeType,
  ) {
    var amounts = List<TokenAmount>(route.path.length);
    var nextPairs = List<Pair>(route.pairs.length);
    if (tradeType == TradeType.EXACT_INPUT) {
      assert(amount.currency == route.input);

      amounts[0] = wrappedAmount(amount, route.chainId);
      for (var i = 0; i < route.path.length - 1; i++) {
        var pair = route.pairs[i];
        var outputAmountAndNextPair = pair.getOutputAmount(amounts[i]);
        amounts[i + 1] = outputAmountAndNextPair[0];
        nextPairs[i] = outputAmountAndNextPair[1];
      }
    } else {
      assert(amount.currency == route.output);

      amounts.last = wrappedAmount(amount, route.chainId);
      for (var i = route.path.length - 1; i > 0; i--) {
        var pair = route.pairs[i - 1];

        var inputAmountAndNextPair = pair.getInputAmount(amounts[i]);
        print('abc: ${(inputAmountAndNextPair[0] as TokenAmount).value.getInWei}');
        amounts[i - 1] = inputAmountAndNextPair[0];
        nextPairs[i - 1] = inputAmountAndNextPair[1];
      }
    }

    inputAmount = tradeType == TradeType.EXACT_INPUT
        ? amount
        : route.input == ETHER
            ? CurrencyAmount.ether(EtherAmount.inWei(amounts.first.value.getInWei))
            : amounts.first;

    outputAmount = tradeType == TradeType.EXACT_OUTPUT
        ? amount
        : route.input == ETHER
            ? CurrencyAmount.ether(EtherAmount.inWei(amounts.last.value.getInWei))
            : amounts.last;

    executionPrice = Price(inputAmount.currency, outputAmount.currency, Decimal.parse('${inputAmount.value.getInWei / outputAmount.value.getInWei}'));

    priceImpact = computePriceImpact(route.midPrice(), inputAmount, outputAmount);
  }

  CurrencyAmount minimumAmountOut(Decimal slippageTolerancePercent) {
    assert(!(slippageTolerancePercent < Decimal.zero));
    if (tradeType == TradeType.EXACT_OUTPUT) {
      return outputAmount;
    } else {
      var slippageAdjustedAmountOut = (BigInt.from(((Decimal.one + slippageTolerancePercent / Decimal.fromInt(100)).inverse * Decimal.fromInt(10000)).ceil().toInt()) * outputAmount.value.getInWei) ~/ BigInt.from(10000);
      return outputAmount is TokenAmount ? TokenAmount((outputAmount as TokenAmount).token, EtherAmount.inWei(slippageAdjustedAmountOut)) : CurrencyAmount.ether(EtherAmount.inWei(slippageAdjustedAmountOut));
    }
  }

  CurrencyAmount maximumAmountIn(Decimal slippageTolerancePercent) {
    assert(!(slippageTolerancePercent < Decimal.zero));

    if (tradeType == TradeType.EXACT_INPUT) {
      return inputAmount;
    } else {
      var slippageAdjustedAmountIn = (BigInt.from(((Decimal.one + slippageTolerancePercent / Decimal.fromInt(100)) * Decimal.fromInt(10000)).ceil().toInt()) * inputAmount.value.getInWei) ~/ BigInt.from(10000);
      return outputAmount is TokenAmount ? TokenAmount((outputAmount as TokenAmount).token, EtherAmount.inWei(slippageAdjustedAmountIn)) : CurrencyAmount.ether(EtherAmount.inWei(slippageAdjustedAmountIn));
    }
  }
}
