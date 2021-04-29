import 'package:test/test.dart';

import 'package:decimal/decimal.dart';
import 'package:uniswap_sdk_dart/src/constants.dart';
import 'package:uniswap_sdk_dart/src/core/Pair.dart';
import 'package:uniswap_sdk_dart/src/core/Route.dart';
import 'package:uniswap_sdk_dart/src/core/Trade.dart';
import 'package:uniswap_sdk_dart/src/core/currency/CurrencyAmount.dart';
import 'package:uniswap_sdk_dart/src/core/token/Token.dart';
import 'package:uniswap_sdk_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/web3dart.dart';

final token0 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18, 't0');
final token1 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18, 't1');
final token2 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000003'), 18, 't2');
final token3 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000004'), 18, 't3');

final pair_0_1 = Pair(TokenAmount(token0, EtherAmount.inWei(BigInt.from(1000))), TokenAmount(token1, EtherAmount.inWei(BigInt.from(1000))));
final pair_0_2 = Pair(TokenAmount(token0, EtherAmount.inWei(BigInt.from(1000))), TokenAmount(token2, EtherAmount.inWei(BigInt.from(1100))));
final pair_0_3 = Pair(TokenAmount(token0, EtherAmount.inWei(BigInt.from(1000))), TokenAmount(token3, EtherAmount.inWei(BigInt.from(900))));
final pair_1_2 = Pair(TokenAmount(token1, EtherAmount.inWei(BigInt.from(1200))), TokenAmount(token2, EtherAmount.inWei(BigInt.from(1000))));
final pair_1_3 = Pair(TokenAmount(token1, EtherAmount.inWei(BigInt.from(1200))), TokenAmount(token3, EtherAmount.inWei(BigInt.from(1300))));

final pair_weth_0 = Pair(
  TokenAmount(WETH[ChainId.MAINNET], EtherAmount.inWei(BigInt.from(1000))),
  TokenAmount(token0, EtherAmount.inWei(BigInt.from(1300))),
);

final empty_pair_0_1 = Pair(TokenAmount(token0, EtherAmount.zero()), TokenAmount(token1, EtherAmount.zero()));

void main() {
  group('Trade', () {
    test('can be constructed with ETHER as input', () {
      final trade = Trade(
        Route([pair_weth_0], ETHER),
        CurrencyAmount.ether(EtherAmount.inWei(BigInt.from(100))),
        TradeType.EXACT_INPUT,
      );
      expect(trade.inputAmount.currency == ETHER, equals(true));
      expect(trade.outputAmount.currency, equals(token0));
    });
    test('can be constructed with ETHER as input for exact output', () {
      final trade = Trade(
        Route([pair_weth_0], ETHER, token0),
        TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))),
        TradeType.EXACT_OUTPUT,
      );
      expect(trade.inputAmount.currency == ETHER, equals(true));
      expect(trade.outputAmount.currency, equals(token0));
    });

    test('can be constructed with ETHER as output', () {
      final trade = Trade(
        Route([pair_weth_0], token0, ETHER),
        CurrencyAmount.ether(EtherAmount.inWei(BigInt.from(100))),
        TradeType.EXACT_OUTPUT,
      );
      expect(trade.inputAmount.currency, equals(token0));
      expect(trade.outputAmount.currency == ETHER, equals(true));
    });
    test('can be constructed with ETHER as output for exact input', () {
      final trade = Trade(
        Route([pair_weth_0], token0, ETHER),
        TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))),
        TradeType.EXACT_INPUT,
      );
      expect(trade.inputAmount.currency, equals(token0));
      expect(trade.outputAmount.currency == ETHER, equals(true));
    });

    group('.bestTradeExactIn()', () {
      test('throws with empty pairs', () {
        expect(() => Trade.bestTradeExactIn([], TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), token2), throwsA(isA<AssertionError>()));
      });

      test('throws with max hops of 0', () {
        expect(() => Trade.bestTradeExactIn([pair_0_2], TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), token2, maxHops: 0), throwsA(isA<AssertionError>()));
      });

      test('provides best route', () {
        final result = Trade.bestTradeExactIn([pair_0_1, pair_0_2, pair_1_2], TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), token2);

        expect(result.length, equals(2));
        expect(result[0].route.pairs.length, equals(1));
        expect(result[0].route.path, equals([token0, token2]));
        expect(result[0].inputAmount, equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(100)))));
        expect(result[0].outputAmount, equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(99)))));

        expect(result[1].route.pairs.length, equals(2));
        expect(result[1].route.path, equals([token0, token1, token2]));
        expect(result[1].inputAmount, equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(100)))));
        expect(result[1].outputAmount, equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(69)))));
      });

      test('doesnt throw for zero liquidity pairs', () {
        expect(
            Trade.bestTradeExactIn(
              [empty_pair_0_1],
              TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))),
              token1,
            ).isEmpty,
            equals(true));
      });

      test('respects maxHops', () {
        final result = Trade.bestTradeExactIn(
          [pair_0_1, pair_0_2, pair_1_2],
          TokenAmount(token0, EtherAmount.inWei(BigInt.from(10))),
          token2,
          maxHops: 1,
        );
        expect(result.length, equals(1));
        expect(result[0].route.pairs.length, equals(1));
        expect(result[0].route.path, equals([token0, token2]));
      });

      test('insufficient input for one pair', () {
        final result = Trade.bestTradeExactIn(
          [pair_0_1, pair_0_2, pair_1_2],
          TokenAmount(token0, EtherAmount.inWei(BigInt.from(1))),
          token2,
        );
        expect(result.length, equals(1));
        expect(result[0].route.pairs.length, equals(1));
        expect(result[0].route.path, equals([token0, token2]));
        expect(result[0].outputAmount, equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(1)))));
      });

      test('respects n', () {
        final result = Trade.bestTradeExactIn(
          [pair_0_1, pair_0_2, pair_1_2],
          TokenAmount(token0, EtherAmount.inWei(BigInt.from(10))),
          token2,
          maxNumResults: 1,
        );
        expect(result.length, equals(1));
      });

      test('no path', () {
        final result = Trade.bestTradeExactIn(
          [pair_0_1, pair_0_3, pair_1_3],
          TokenAmount(token0, EtherAmount.inWei(BigInt.from(10))),
          token2,
        );
        expect(result.isEmpty, equals(true));
      });

      test('works for ETHER currency input', () {
        final result = Trade.bestTradeExactIn(
          [pair_weth_0, pair_0_1, pair_0_3, pair_1_3],
          CurrencyAmount.ether(EtherAmount.inWei(BigInt.from(100))),
          token3,
        );

        expect(result.length, equals(2));
        expect(result[0].inputAmount.currency == ETHER, equals(true));
        expect(result[0].route.path, equals([WETH[ChainId.MAINNET], token0, token1, token3]));
        expect(result[0].outputAmount.currency, equals(token3));

        expect(result[1].inputAmount.currency == ETHER, equals(true));
        expect(result[1].route.path, equals([WETH[ChainId.MAINNET], token0, token3]));
        expect(result[1].outputAmount.currency, equals(token3));
      });

      test('works for ETHER currency output', () {
        final result = Trade.bestTradeExactIn(
          [pair_weth_0, pair_0_1, pair_0_3, pair_1_3],
          TokenAmount(token3, EtherAmount.inWei(BigInt.from(100))),
          ETHER,
        );

        expect(result.length, equals(2));

        expect(result[0].inputAmount.currency, equals(token3));
        expect(result[0].route.path, equals([token3, token0, WETH[ChainId.MAINNET]]));
        expect(result[0].outputAmount.currency == ETHER, equals(true));

        expect(result[1].inputAmount.currency, equals(token3));
        expect(result[1].route.path, equals([token3, token1, token0, WETH[ChainId.MAINNET]]));
        expect(result[1].outputAmount.currency == ETHER, equals(true));
      });
    });
    group('.bestTradeExactOut()', () {
      test('throws with empty pairs', () {
        expect(() => Trade.bestTradeExactOut([], token0, TokenAmount(token0, EtherAmount.inWei(BigInt.from(100)))), throwsA(isA<AssertionError>()));
      });

      test('throws with max hops of 0', () {
        expect(() => Trade.bestTradeExactOut([pair_0_2], token0, TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), maxHops: 0), throwsA(isA<AssertionError>()));
      });

      test('provides best route', () {
        final result = Trade.bestTradeExactOut(
          [pair_0_1, pair_0_2, pair_1_2],
          token0,
          TokenAmount(token2, EtherAmount.inWei(BigInt.from(100))),
        );

        expect(result.length, equals(2));
        expect(result[0].route.pairs.length, equals(1));
        expect(result[0].route.path, equals([token0, token2]));
        expect(result[0].inputAmount, equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(101)))));
        expect(result[0].outputAmount, equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(100)))));

        expect(result[1].route.pairs.length, equals(2));
        expect(result[1].route.path, equals([token0, token1, token2]));
        expect(result[1].inputAmount, equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(156)))));
        expect(result[1].outputAmount, equals(TokenAmount(token2, EtherAmount.inWei(BigInt.from(100)))));
      });

      test('doesnt throw for zero liquidity pairs', () {
        expect(
            Trade.bestTradeExactOut(
              [empty_pair_0_1],
              token1,
              TokenAmount(token1, EtherAmount.inWei(BigInt.from(100))),
            ).isEmpty,
            equals(true));
      });

      test('respects maxHops', () {
        final result = Trade.bestTradeExactOut(
          [pair_0_1, pair_0_2, pair_1_2],
          token0,
          TokenAmount(token2, EtherAmount.inWei(BigInt.from(10))),
          maxHops: 1,
        );
        expect(result.length, equals(1));
        expect(result[0].route.pairs.length, equals(1));
        expect(result[0].route.path, equals([token0, token2]));
      });

      test('insufficient liquidity', () {
        final result = Trade.bestTradeExactOut(
          [pair_0_1, pair_0_2, pair_1_2],
          token0,
          TokenAmount(token2, EtherAmount.inWei(BigInt.from(1200))),
        );
        expect(result.isEmpty, equals(true));
      });

      test('insufficient liquidity in one pair but not the other', () {
        final result = Trade.bestTradeExactOut(
          [pair_0_1, pair_0_2, pair_1_2],
          token0,
          TokenAmount(token2, EtherAmount.inWei(BigInt.from(1050))),
        );
        expect(result.length, equals(1));
      });

      test('respects n', () {
        final result = Trade.bestTradeExactOut(
          [pair_0_1, pair_0_2, pair_1_2],
          token0,
          TokenAmount(token2, EtherAmount.inWei(BigInt.from(10))),
          maxNumResults: 1,
        );
        expect(result.length, equals(1));
      });

      test('no path', () {
        final result = Trade.bestTradeExactOut(
          [pair_0_1, pair_0_3, pair_1_3],
          token0,
          TokenAmount(token2, EtherAmount.inWei(BigInt.from(10))),
        );
        expect(result.isEmpty, equals(true));
      });

      test('works for ETHER currency input', () {
        final result = Trade.bestTradeExactOut(
          [pair_weth_0, pair_0_1, pair_0_3, pair_1_3],
          ETHER,
          TokenAmount(token3, EtherAmount.inWei(BigInt.from(100))),
        );

        expect(result.length, equals(2));
        expect(result[0].inputAmount.currency == ETHER, equals(true));
        expect(result[0].route.path, equals([WETH[ChainId.MAINNET], token0, token1, token3]));
        expect(result[0].outputAmount.currency, equals(token3));

        expect(result[1].inputAmount.currency == ETHER, equals(true));
        expect(result[1].route.path, equals([WETH[ChainId.MAINNET], token0, token3]));
        expect(result[1].outputAmount.currency, equals(token3));
      });

      test('works for ETHER currency output', () {
        final result = Trade.bestTradeExactOut(
          [pair_weth_0, pair_0_1, pair_0_3, pair_1_3],
          token3,
          CurrencyAmount.ether(EtherAmount.inWei(BigInt.from(100))),
        );

        expect(result.length, equals(2));

        expect(result[0].inputAmount.currency, equals(token3));
        expect(result[0].route.path, equals([token3, token0, WETH[ChainId.MAINNET]]));
        expect(result[0].outputAmount.currency == ETHER, equals(true));

        expect(result[1].inputAmount.currency, equals(token3));
        expect(result[1].route.path, equals([token3, token1, token0, WETH[ChainId.MAINNET]]));
        expect(result[1].outputAmount.currency == ETHER, equals(true));
      });
    });

    group('.minimumAmountOut()', () {
      group('tradeType = EXACT_INPUT', () {
        final exactIn = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_INPUT);

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
        final exactOut = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token2, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_OUTPUT);

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
        final exactIn = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_INPUT);

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
      group('tradeType = EXACT_OUTPUT', () {
        final exactOut = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token2, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_OUTPUT);

        test('throws if less than 0', () {
          expect(() => exactOut.maximumAmountIn(Decimal.parse('-1')), throwsA(isA<AssertionError>()));
        });

        test('returns exact if 0', () {
          expect(exactOut.maximumAmountIn(Decimal.parse('0')), equals(exactOut.inputAmount));
        });
        test('returns slippage amount if nonzero', () {
          expect(exactOut.maximumAmountIn(Decimal.parse('0')), equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(156)))));
          expect(exactOut.maximumAmountIn(Decimal.parse('5')), equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(163)))));
          expect(exactOut.maximumAmountIn(Decimal.parse('200')), equals(TokenAmount(token0, EtherAmount.inWei(BigInt.from(468)))));
        });
      });
    });
  });
}
