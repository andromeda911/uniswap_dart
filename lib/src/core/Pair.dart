import 'dart:typed_data' show Uint8List;

import 'package:uniswap_dart/src/core/TokenAmount.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../constants.dart';
import 'Token.dart';

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
}
