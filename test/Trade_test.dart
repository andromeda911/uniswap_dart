import 'package:test/test.dart';

import 'package:decimal/decimal.dart';
import 'package:uniswap_dart/src/constants.dart';
import 'package:uniswap_dart/src/core/Pair.dart';
import 'package:uniswap_dart/src/core/Route.dart';
import 'package:uniswap_dart/src/core/Trade.dart';
import 'package:uniswap_dart/src/core/token/Token.dart';
import 'package:uniswap_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/web3dart.dart';

var token0 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18, 't0');
var token1 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18, 't1');
var token2 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000003'), 18, 't2');
var token3 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000004'), 18, 't3');

var pair_0_1 = Pair(TokenAmount(token0, EtherAmount.inWei(BigInt.from(1000))), TokenAmount(token1, EtherAmount.inWei(BigInt.from(1000))));
var pair_0_2 = Pair(TokenAmount(token0, EtherAmount.inWei(BigInt.from(1000))), TokenAmount(token2, EtherAmount.inWei(BigInt.from(1100))));
var pair_0_3 = Pair(TokenAmount(token0, EtherAmount.inWei(BigInt.from(1000))), TokenAmount(token3, EtherAmount.inWei(BigInt.from(900))));
var pair_1_2 = Pair(TokenAmount(token1, EtherAmount.inWei(BigInt.from(1200))), TokenAmount(token2, EtherAmount.inWei(BigInt.from(1000))));
var pair_1_3 = Pair(TokenAmount(token1, EtherAmount.inWei(BigInt.from(1200))), TokenAmount(token3, EtherAmount.inWei(BigInt.from(1300))));

void main() {
  group('Trade', () {
    group('.minimumAmountOut()', () {
      group('tradeType = EXACT_INPUT', () {
        var exactIn = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_INPUT);

        test('throws if less than 0', () {
          expect(() => exactIn.minimumAmountOut(Decimal.parse('-1')), throwsA(isA<AssertionError>()));
        });

        test('returns exact if 0', () {
          expect(exactIn.minimumAmountOut(Decimal.parse('0')), equals(exactIn.outputAmount));
        });

        test('returns exact if nonzero', () {
          expect(exactIn.minimumAmountOut(Decimal.parse('0')), equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(69)))));
          expect(exactIn.minimumAmountOut(Decimal.parse('5')), equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(65)))));
          expect(exactIn.minimumAmountOut(Decimal.parse('200')), equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(23)))));
        });
      });
      group('tradeType = EXACT_OUTPUT', () {
        var exactOut = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token2, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_OUTPUT);

        test('throws if less than 0', () {
          expect(() => exactOut.minimumAmountOut(Decimal.parse('-1')), throwsA(isA<AssertionError>()));
        });

        test('returns exact if 0', () {
          expect(exactOut.minimumAmountOut(Decimal.parse('0')), equals(exactOut.outputAmount));
        });
        test('returns exact if nonzero', () {
          expect(exactOut.minimumAmountOut(Decimal.parse('0')), equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(100)))));
          expect(exactOut.minimumAmountOut(Decimal.parse('5')), equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(100)))));
          expect(exactOut.minimumAmountOut(Decimal.parse('200')), equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(100)))));
        });
      });
    });
    group('.maximumAmountIn()', () {
      group('tradeType = EXACT_INPUT', () {
        var exactIn = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_INPUT);

        test('throws if less than 0', () {
          expect(() => exactIn.maximumAmountIn(Decimal.parse('-1')), throwsA(isA<AssertionError>()));
        });

        test('returns exact if 0', () {
          expect(exactIn.maximumAmountIn(Decimal.parse('0')), equals(exactIn.inputAmount));
        });

        test('returns exact if nonzero', () {
          expect(exactIn.maximumAmountIn(Decimal.parse('0')), equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(100)))));
          expect(exactIn.maximumAmountIn(Decimal.parse('5')), equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(100)))));
          expect(exactIn.maximumAmountIn(Decimal.parse('200')), equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(100)))));
        });
      });
    });
  });
}
