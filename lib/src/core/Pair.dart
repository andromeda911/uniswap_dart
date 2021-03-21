import 'dart:typed_data' show Uint8List;

import 'package:uniswap_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../constants.dart';
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

  List<TokenAmount> tokenAmounts;

  Pair(TokenAmount tokenAmountA, TokenAmount tokenAmountB, [this.liquidityToken]) {
    tokenAmounts = tokenAmountA.token.sortsBefore(tokenAmountB.token) ? [tokenAmountA, tokenAmountB] : [tokenAmountB, tokenAmountA];

    liquidityToken ??= Token(
      tokenAmounts.first.token.chainId,
      Pair.getAddress(tokenAmounts[0].token, tokenAmounts[1].token),
      18,
      'UNI-V2',
      'Uniswap V2',
    );
  }

  int get chainId {
    return token0.chainId;
  }

  Token get token0 => tokenAmounts[0].token;

  Token get token1 => tokenAmounts[1].token;

  TokenAmount get reserve0 => tokenAmounts[0];

  TokenAmount get reserve1 => tokenAmounts[1];

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

    if (reserve0.value.getInWei == BigInt.zero || reserve1.value.getInWei == BigInt.zero) {
      throw InsufficientReservesError();
    }
    var inputReserve = reserveOf(inputAmount.token);
    var outputToken = inputAmount.token == token0 ? token1 : token0;
    var outputReserve = reserveOf(outputToken);

    var inputAmountWithFee = inputAmount.value.getInWei * BigInt.from(997);

    var outputAmount = TokenAmount(
      outputToken,
      EtherAmount.inWei((inputAmountWithFee * outputReserve.value.getInWei) ~/ (inputReserve.value.getInWei * BigInt.from(1000) + inputAmountWithFee)),
    );

    if (outputAmount.value.getInWei == BigInt.zero) {
      throw InsufficientInputAmountError();
    }
    return [outputAmount, Pair(inputReserve + inputAmount, outputReserve - outputAmount)];
  }

  /// returns list of values :
  /// 0 = inputAmount : [TokenAmount]
  /// 1 = nextPair : [Pair]
  List<dynamic> getInputAmount(TokenAmount outputAmount) {
    assert(involvesToken(outputAmount.token));

    print(reserve0.value.getInWei == BigInt.zero);
    print(reserve1.value.getInWei == BigInt.zero);

    print(outputAmount.value.getInWei >= reserveOf(outputAmount.token).value.getInWei);
    print(outputAmount.value.getInWei);
    print(reserveOf(outputAmount.token).value.getInWei);

    if (reserve0.value.getInWei == BigInt.zero || reserve1.value.getInWei == BigInt.zero || outputAmount.value.getInWei >= reserveOf(outputAmount.token).value.getInWei) {
      throw InsufficientReservesError();
    }
    var outputReserve = reserveOf(outputAmount.token);
    var inputToken = outputAmount.token == token0 ? token1 : token0;
    var inputReserve = reserveOf(inputToken);

    var inputAmount = TokenAmount(
      inputToken,
      EtherAmount.inWei(
        ((inputReserve.value.getInWei * outputAmount.value.getInWei) * BigInt.from(1000) ~/ (outputReserve.value.getInWei * outputAmount.value.getInWei) * BigInt.from(997)) + BigInt.one,
      ),
    );

    return [inputAmount, Pair(inputReserve + inputAmount, outputReserve - outputAmount)];
  }
}
