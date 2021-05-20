import 'dart:typed_data' show Uint8List;

import 'package:uniswap_sdk_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../constants.dart';
import 'Price.dart';
import 'token/Token.dart';

EthereumAddress computePairAddress(EthereumAddress factoryAddress, Token tokenA, Token tokenB) {
  var tokens = tokenA.sortsBefore(tokenB) ? [tokenA, tokenB] : [tokenB, tokenA];

  var startBytes = hexToBytes('0xff');
  var factoryBytes = hexToBytes(factoryAddress.hex);
  var saltBytes = keccak256(hexToBytes(tokens[0].address.hexNo0x + tokens[1].address.hexNo0x));
  var initCodeHashBytes = hexToBytes(INIT_CODE_HASH);

  return EthereumAddress(keccak256(Uint8List.fromList(startBytes + factoryBytes + saltBytes + initCodeHashBytes)).sublist(12));
}

class Pair {
  static EthereumAddress getAddress(Token tokenA, Token tokenB) {
    return computePairAddress(FACTORY_ADDRESS, tokenA, tokenB);
  }

  Token liquidityToken;

  List<TokenAmount> _tokenAmounts;

  Pair(TokenAmount tokenAmountA, TokenAmount tokenAmountB, [Token liqToken]) {
    _tokenAmounts = tokenAmountA.token.sortsBefore(tokenAmountB.token) ? [tokenAmountA, tokenAmountB] : [tokenAmountB, tokenAmountA];

    liquidityToken ??= liqToken ??
        Token(
          _tokenAmounts.first.token.chainId,
          Pair.getAddress(_tokenAmounts[0].token, _tokenAmounts[1].token),
          18,
          'UNI-V2',
          'Uniswap V2',
        );
  }

  Price get token0Price => Price(token0, token1, _tokenAmounts[1].value / _tokenAmounts[0].value);

  Price get token1Price => Price(token1, token0, _tokenAmounts[0].value / _tokenAmounts[1].value);

  Price priceOf(Token token) {
    assert(involvesToken(token));
    return token == token0 ? token0Price : token1Price;
  }

  int get chainId {
    return token0.chainId;
  }

  Token get token0 => _tokenAmounts[0].token;

  Token get token1 => _tokenAmounts[1].token;

  TokenAmount get reserve0 => _tokenAmounts[0];

  TokenAmount get reserve1 => _tokenAmounts[1];

  bool involvesToken(Token token) => token == token0 || token == token1;
  TokenAmount reserveOf(Token token) {
    assert(involvesToken(token));
    return token == token0 ? reserve0 : reserve1;
  }

  /// returns list of values :
  /// 0 = outputAmount : [TokenAmount]
  /// 1 = nextPair : [Pair]
  List<dynamic> getOutputAmount(TokenAmount inputAmount) {
    assert(involvesToken(inputAmount.token));

    if (reserve0.raw.getInWei == BigInt.zero || reserve1.raw.getInWei == BigInt.zero) {
      throw InsufficientReservesError();
    }
    var inputReserve = reserveOf(inputAmount.token);
    var outputToken = inputAmount.token == token0 ? token1 : token0;
    var outputReserve = reserveOf(outputToken);

    var inputAmountWithFee = inputAmount.raw.getInWei * BI997;

    var outputAmount = TokenAmount(
      outputToken,
      EtherAmount.inWei((inputAmountWithFee * outputReserve.raw.getInWei) ~/ (inputReserve.raw.getInWei * BI1000 + inputAmountWithFee)),
    );

    if (outputAmount.raw.getInWei == BigInt.zero) {
      throw InsufficientInputAmountError();
    }
    return [outputAmount, Pair(inputReserve + inputAmount, outputReserve - outputAmount)];
  }

  /// returns list of values :
  /// 0 = inputAmount : [TokenAmount]
  /// 1 = nextPair : [Pair]
  List<dynamic> getInputAmount(TokenAmount outputAmount) {
    assert(involvesToken(outputAmount.token));

    if (reserve0.raw.getInWei == BigInt.zero || reserve1.raw.getInWei == BigInt.zero || outputAmount.raw.getInWei >= reserveOf(outputAmount.token).raw.getInWei) {
      throw InsufficientReservesError();
    }
    var outputReserve = reserveOf(outputAmount.token);
    var inputToken = outputAmount.token == token0 ? token1 : token0;
    var inputReserve = reserveOf(inputToken);
    var numerator = inputReserve.raw.getInWei * outputAmount.raw.getInWei * BI1000;
    var denominator = (outputReserve.raw.getInWei - outputAmount.raw.getInWei) * BI997;

    var inputAmount = TokenAmount(
      inputToken,
      EtherAmount.inWei(
        (numerator ~/ denominator) + BigInt.one,
      ),
    );

    return [inputAmount, Pair(inputReserve + inputAmount, outputReserve - outputAmount)];
  }

  TokenAmount getLiquidityMinted(
    TokenAmount totalSupply,
    TokenAmount tokenAmountA,
    TokenAmount tokenAmountB,
  ) {
    assert(totalSupply.token == liquidityToken);
    var tokenAmounts = tokenAmountA.token.sortsBefore(tokenAmountB.token) ? [tokenAmountA, tokenAmountB] : [tokenAmountB, tokenAmountA];
    assert(tokenAmounts[0].token == token0 && tokenAmounts[1].token == token1);

    EtherAmount liquidity;

    if (totalSupply.raw == EtherAmount.zero()) {
      liquidity = EtherAmount.inWei(babylonianSqrt(tokenAmounts[0].raw.getInWei * tokenAmounts[1].raw.getInWei) - MINIMUM_LIQUIDITY);
    } else {
      var amount0 = (tokenAmounts[0].raw.getInWei * totalSupply.raw.getInWei) ~/ reserve0.raw.getInWei;
      var amount1 = (tokenAmounts[1].raw.getInWei * totalSupply.raw.getInWei) ~/ reserve1.raw.getInWei;

      liquidity = EtherAmount.inWei(amount0 >= amount1 ? amount0 : amount1);
    }
    if (!(liquidity.getInWei > BigInt.zero)) {
      throw InsufficientInputAmountError();
    }
    return TokenAmount(liquidityToken, liquidity);
  }

  TokenAmount getLiquidityValue(
    Token token,
    TokenAmount totalSupply,
    TokenAmount liquidity,
    BigInt kLast, [
    bool feeOn = false,
  ]) {
    assert(involvesToken(token));
    assert(totalSupply.token == liquidityToken);
    assert(liquidity.token == liquidityToken);
    assert(liquidity.raw.getInWei <= totalSupply.raw.getInWei);
    TokenAmount totalSupplyAdjusted;

    if (!feeOn) {
      totalSupplyAdjusted = totalSupply;
      print(1);
    } else {
      assert(kLast != null);
      if (kLast != BigInt.zero) {
        var rootK = babylonianSqrt(reserve0.raw.getInWei * reserve1.raw.getInWei);
        var rootKLast = babylonianSqrt(kLast);
        print(2);
        print(rootK);
        print(rootKLast);

        if (rootK > rootKLast) {
          final numerator = totalSupply.raw.getInWei * (rootK - rootKLast);
          final denominator = rootK * BigInt.from(5) + rootKLast;
          final feeLiquidity = numerator ~/ denominator;
          print(numerator);
          print(denominator);
          print(feeLiquidity);

          totalSupplyAdjusted = totalSupply + TokenAmount(liquidityToken, EtherAmount.inWei(feeLiquidity));
          print(totalSupplyAdjusted.raw.getInWei);
        } else {
          totalSupplyAdjusted = totalSupply;
        }
      } else {
        totalSupplyAdjusted = totalSupply;
      }
    }

    return TokenAmount(
      token,
      EtherAmount.inWei((liquidity.raw.getInWei * reserveOf(token).raw.getInWei) ~/ totalSupplyAdjusted.raw.getInWei),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is Pair) {
      return token0.address == other.token0.address && token1.address == other.token1.address && chainId == other.chainId;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => token0.hashCode ^ token1.hashCode;
}
