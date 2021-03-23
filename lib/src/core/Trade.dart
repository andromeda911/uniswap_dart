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

int inputOutputComparator(InputOutput a, InputOutput b) {
  assert(a.inputAmount.currency == b.inputAmount.currency);
  assert(a.outputAmount.currency == b.outputAmount.currency);

  if (a.outputAmount == b.outputAmount) {
    if (a.inputAmount == b.inputAmount) {
      return 0;
    }
    // trade A requires less input than trade B, so A should come first
    if (a.inputAmount.value.getInWei < b.inputAmount.value.getInWei) {
      return -1;
    } else {
      return 1;
    }
  } else {
    // tradeA has less output than trade B, so should come second
    if (a.outputAmount.value.getInWei < b.outputAmount.value.getInWei) {
      return 1;
    } else {
      return -1;
    }
  }
}

int tradeComparator(Trade a, Trade b) {
  var ioComp = inputOutputComparator(InputOutput(a.inputAmount, a.outputAmount), InputOutput(b.inputAmount, b.outputAmount));

  if (ioComp != 0) {
    return ioComp;
  }

  // consider lowest slippage next, since these are less likely to fail
  if (a.priceImpact < b.priceImpact) {
    return -1;
  } else if (a.priceImpact > b.priceImpact) {
    return 1;
  }

  // finally consider the number of hops since each hop costs gas
  return a.route.path.length - b.route.pairs.length;
}

class InputOutput {
  CurrencyAmount inputAmount;
  CurrencyAmount outputAmount;
  InputOutput(this.inputAmount, this.outputAmount);
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
        : route.output == ETHER
            ? CurrencyAmount.ether(EtherAmount.inWei(amounts.last.value.getInWei))
            : amounts.last;

    executionPrice = Price(inputAmount.currency, outputAmount.currency, Decimal.parse('${inputAmount.value.getInWei / outputAmount.value.getInWei}'));

    priceImpact = computePriceImpact(route.midPrice(), inputAmount, outputAmount);
  }

  static Trade exactIn(Route route, CurrencyAmount amountIn) {
    return Trade(route, amountIn, TradeType.EXACT_INPUT);
  }

  static Trade exactOut(Route route, CurrencyAmount amountout) {
    return Trade(route, amountout, TradeType.EXACT_OUTPUT);
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
      return inputAmount is TokenAmount ? TokenAmount((inputAmount as TokenAmount).token, EtherAmount.inWei(slippageAdjustedAmountIn)) : CurrencyAmount.ether(EtherAmount.inWei(slippageAdjustedAmountIn));
    }
  }

  static List<Trade> bestTradeExactIn(
    List<Pair> pairs,
    CurrencyAmount currencyAmountIn,
    Currency currencyOut, {
    int maxNumResults = 3,
    int maxHops = 3,
    List<Pair> currentPairs,
    CurrencyAmount originalAmountIn,
    List<Trade> bestTrades,
  }) {
    originalAmountIn ??= currencyAmountIn;
    currentPairs ??= <Pair>[];
    bestTrades ??= <Trade>[];

    assert(pairs.isNotEmpty);
    assert(maxHops > 0);
    assert(originalAmountIn == currencyAmountIn || currentPairs.isNotEmpty);

    var chainId = currencyAmountIn is TokenAmount
        ? currencyAmountIn.token.chainId
        : currencyOut is Token
            ? currencyOut.chainId
            : null;

    assert(chainId != null);

    var amountIn = wrappedAmount(currencyAmountIn, chainId);
    var tokenOut = wrappedCurrency(currencyOut, chainId);

    for (var i = 0; i < pairs.length; i++) {
      final pair = pairs[i];

      // pair irrelevant
      if (pair.token0 != amountIn.token && pair.token1 != amountIn.token) continue;

      if (pair.reserve0.value.getInWei == BigInt.zero || pair.reserve1.value.getInWei == BigInt.zero) continue;

      TokenAmount amountOut;
      try {
        amountOut = pair.getOutputAmount(amountIn)[0];

        // input too low
      } on InsufficientInputAmountError catch (_) {
        continue;
      } catch (e) {
        rethrow;
      }

      // we have arrived at the output token, so this is the final trade of one of the paths
      if (amountOut.token == tokenOut) {
        bestTrades.add(
          Trade(
            Route([...currentPairs, pair], originalAmountIn.currency, currencyOut),
            originalAmountIn,
            TradeType.EXACT_INPUT,
          ),
        );

        bestTrades.sort(tradeComparator);
        if (bestTrades.length > maxNumResults) {
          bestTrades = bestTrades.sublist(0, maxNumResults);

          bestTrades.removeRange(maxNumResults - 1, bestTrades.length - 1);
        }
      } else if (maxHops > 1 && pairs.length > 1) {
        var pairsExcludingThisPair = [...(pairs.sublist(0, i)), ...(pairs.sublist(i + 1, pairs.length))];

        // otherwise, consider all the other paths that lead from this token as long as we have not exceeded maxHops

        Trade.bestTradeExactIn(
          pairsExcludingThisPair,
          amountOut,
          currencyOut,
          maxNumResults: maxNumResults,
          maxHops: maxHops - 1,
          currentPairs: [...currentPairs, pair],
          originalAmountIn: originalAmountIn,
          bestTrades: bestTrades,
        );
      }
    }
    return bestTrades;
  }

  static List<Trade> bestTradeExactOut(
    List<Pair> pairs,
    Currency currencyIn,
    CurrencyAmount currencyAmountOut, {
    int maxNumResults = 3,
    int maxHops = 3,
    List<Pair> currentPairs,
    CurrencyAmount originalAmountOut,
    List<Trade> bestTrades,
  }) {
    originalAmountOut ??= currencyAmountOut;
    currentPairs ??= <Pair>[];
    bestTrades ??= <Trade>[];

    assert(pairs.isNotEmpty);
    assert(maxHops > 0);
    assert(originalAmountOut == currencyAmountOut || currentPairs.isNotEmpty);

    var chainId = currencyAmountOut is TokenAmount
        ? currencyAmountOut.token.chainId
        : currencyIn is Token
            ? currencyIn.chainId
            : null;

    assert(chainId != null);

    var amountOut = wrappedAmount(currencyAmountOut, chainId);
    var tokenIn = wrappedCurrency(currencyIn, chainId);

    for (var i = 0; i < pairs.length; i++) {
      final pair = pairs[i];

      // pair irrelevant
      if (pair.token0 != amountOut.token && pair.token1 != amountOut.token) continue;

      if (pair.reserve0.value.getInWei == BigInt.zero || pair.reserve1.value.getInWei == BigInt.zero) continue;

      TokenAmount amountIn;
      try {
        amountIn = pair.getInputAmount(amountOut)[0];

        // input too low
      } on InsufficientReservesError catch (_) {
        continue;
      } catch (e) {
        rethrow;
      }

      // we have arrived at the output token, so this is the final trade of one of the paths
      if (amountIn.token == tokenIn) {
        bestTrades.add(
          Trade(
            Route([pair, ...currentPairs], currencyIn, originalAmountOut.currency),
            originalAmountOut,
            TradeType.EXACT_OUTPUT,
          ),
        );

        bestTrades.sort(tradeComparator);
        if (bestTrades.length > maxNumResults) {
          bestTrades.removeRange(maxNumResults - 1, bestTrades.length - 1);
        }
      } else if (maxHops > 1 && pairs.length > 1) {
        var pairsExcludingThisPair = [...(pairs.sublist(0, i)), ...(pairs.sublist(i + 1, pairs.length))];

        // otherwise, consider all the other paths that lead from this token as long as we have not exceeded maxHops

        Trade.bestTradeExactOut(
          pairsExcludingThisPair,
          currencyIn,
          amountIn,
          maxNumResults: maxNumResults,
          maxHops: maxHops - 1,
          currentPairs: [pair, ...currentPairs],
          originalAmountOut: originalAmountOut,
          bestTrades: bestTrades,
        );
      }
    }
    return bestTrades;
  }
}
