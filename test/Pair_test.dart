import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:uniswap_dart/src/constants.dart';
import 'package:uniswap_dart/src/core/Pair.dart';
import 'package:uniswap_dart/src/core/Price.dart';
import 'package:uniswap_dart/src/core/token/Token.dart';
import 'package:uniswap_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  group('computePairAddress()', () {
    test('should correctly compute the pool address', () {
      final tokenA = Token(ChainId.MAINNET, EthereumAddress.fromHex('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'), 18, 'USDC', 'USD Coin');
      final tokenB = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x6B175474E89094C44Da98b954EedeAC495271d0F'), 18, 'DAI', 'DAI Stablecoin');
      final result = computePairAddress(EthereumAddress.fromHex('0x1111111111111111111111111111111111111111'), tokenA, tokenB);
      expect(result, equals(EthereumAddress.fromHex('0xb50b5182D6a47EC53a469395AF44e371d7C76ed4')));
    });

    test('should give same result regardless of token order', () {
      final USDC = Token(ChainId.MAINNET, EthereumAddress.fromHex('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'), 18, 'USDC', 'USD Coin');
      final DAI = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x6B175474E89094C44Da98b954EedeAC495271d0F'), 18, 'DAI', 'DAI Stablecoin');

      var tokenA = USDC;
      var tokenB = DAI;

      final resultA = computePairAddress(EthereumAddress.fromHex('0x1111111111111111111111111111111111111111'), tokenA, tokenB);

      tokenA = DAI;
      tokenB = USDC;

      final resultB = computePairAddress(EthereumAddress.fromHex('0x1111111111111111111111111111111111111111'), tokenA, tokenB);

      expect(resultA, equals(resultB));
    });
  });

  group('Pair()', () {
    final USDC = Token(ChainId.MAINNET, EthereumAddress.fromHex('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'), 18, 'USDC', 'USD Coin');
    final DAI = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x6B175474E89094C44Da98b954EedeAC495271d0F'), 18, 'DAI', 'DAI Stablecoin');

    group('constructor', () {
      test('cannot be used for tokens on different chains', () {
        expect(
          () => Pair(TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))), TokenAmount(WETH9[ChainId.RINKEBY], EtherAmount.inWei(BigInt.from(100)))),
          throwsA(isA<AssertionError>()),
        );
      });
    });
    group('.getAddress', () {
      test('returns the correct address', () {
        expect(Pair.getAddress(USDC, DAI), equals(EthereumAddress.fromHex('0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5')));
      });
    });
    group('.token0', () {
      test('always is the token that sorts before', () {
        expect(
            Pair(
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
            ).token0,
            equals(DAI));
        expect(
            Pair(
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            ).token0,
            equals(DAI));
      });
    });
    group('.token1', () {
      test('always is the token that sorts after', () {
        expect(
            Pair(
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
            ).token1,
            equals(USDC));
        expect(
            Pair(
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            ).token1,
            equals(USDC));
      });
    });
    group('.reserve0', () {
      test('always comes from the token that sorts before', () {
        expect(
            Pair(
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
            ).reserve0,
            equals(TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101)))));
        expect(
            Pair(
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            ).reserve0,
            equals(TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101)))));
      });
    });
    group('.reserve1', () {
      test('always comes from the token that sorts after', () {
        expect(
            Pair(
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
            ).reserve1,
            equals(TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100)))));
        expect(
            Pair(
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            ).reserve1,
            equals(TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100)))));
      });
    });
    group('.token0Price()', () {
      test('returns price of token0 in terms of token1', () {
        expect(
            Pair(
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(101))),
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
            ).token0Price,
            equals(Price(DAI, USDC, Decimal.parse('${100 / 101}'))));
        expect(
            Pair(
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(101))),
            ).token0Price,
            equals(Price(DAI, USDC, Decimal.parse('${100 / 101}'))));
      });
    });
    group('.token1Price()', () {
      test('returns price of token0 in terms of token1', () {
        expect(
            Pair(
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(101))),
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
            ).token1Price,
            equals(Price(USDC, DAI, Decimal.parse('${101 / 100}'))));
        expect(
            Pair(
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(101))),
            ).token1Price,
            equals(Price(USDC, DAI, Decimal.parse('${101 / 100}'))));
      });
    });
    group('.priceOf()', () {
      final pair = Pair(
        TokenAmount(USDC, EtherAmount.inWei(BigInt.from(101))),
        TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
      );
      test('returns price of token in terms of other token', () {
        expect(pair.priceOf(DAI), equals(pair.token0Price));
        expect(pair.priceOf(USDC), equals(pair.token1Price));
      });

      test('throws if invalid token', () {
        expect(() => pair.priceOf(WETH9[ChainId.MAINNET]), throwsA(isA<AssertionError>()));
      });
    });
    group('.geserveOf()', () {
      test('returns reserves of the given token', () {
        expect(
            Pair(
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
            ).reserveOf(USDC),
            equals(TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100)))));
        expect(
            Pair(
              TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
              TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            ).reserveOf(USDC),
            equals(TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100)))));
      });
      test('throws if not in the pair', () {
        expect(
            () => Pair(
                  TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
                  TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
                ).reserveOf(WETH9[ChainId.MAINNET]),
            throwsA(isA<AssertionError>()));
      });
    });

    group('.chainId', () {
      test('returns the token0 chainId', () {
        expect(
          Pair(
            TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
          ).chainId,
          equals(ChainId.MAINNET),
        );
        expect(
          Pair(
            TokenAmount(DAI, EtherAmount.inWei(BigInt.from(100))),
            TokenAmount(USDC, EtherAmount.inWei(BigInt.from(101))),
          ).chainId,
          equals(ChainId.MAINNET),
        );
      });
    });
    group('.involvesToken()', () {
      test('returns the token0 chainId', () {
        expect(
          Pair(
            TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
          ).involvesToken(USDC),
          equals(true),
        );
        expect(
          Pair(
            TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
          ).involvesToken(DAI),
          equals(true),
        );
        expect(
          Pair(
            TokenAmount(USDC, EtherAmount.inWei(BigInt.from(100))),
            TokenAmount(DAI, EtherAmount.inWei(BigInt.from(101))),
          ).involvesToken(WETH9[ChainId.MAINNET]),
          equals(false),
        );
      });
    });
    group('miscellaneous', () {
      test('.getLiquidityMinted():0', () {
        final tokenA = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18);
        final tokenB = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18);
        final pair = Pair(
          TokenAmount(tokenA, EtherAmount.zero()),
          TokenAmount(tokenB, EtherAmount.zero()),
        );
        expect(
          () => pair.getLiquidityMinted(
            TokenAmount(pair.liquidityToken, EtherAmount.zero()),
            TokenAmount(tokenA, EtherAmount.inWei(BigInt.from(1000))),
            TokenAmount(tokenB, EtherAmount.inWei(BigInt.from(1000))),
          ),
          throwsA(isA<InsufficientInputAmountError>()),
        );
        expect(
          () => pair.getLiquidityMinted(
            TokenAmount(pair.liquidityToken, EtherAmount.zero()),
            TokenAmount(tokenA, EtherAmount.inWei(BigInt.from(1000000))),
            TokenAmount(tokenB, EtherAmount.inWei(BigInt.from(1))),
          ),
          throwsA(isA<InsufficientInputAmountError>()),
        );

        final liquidity = pair.getLiquidityMinted(
          TokenAmount(pair.liquidityToken, EtherAmount.zero()),
          TokenAmount(tokenA, EtherAmount.inWei(BigInt.from(1001))),
          TokenAmount(tokenB, EtherAmount.inWei(BigInt.from(1001))),
        );

        expect(liquidity.value, EtherAmount.inWei(BigInt.one));
      });
      test('.getLiquidityMinted():!0', () {
        final tokenA = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18);
        final tokenB = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18);
        final pair = Pair(
          TokenAmount(tokenA, EtherAmount.inWei(BigInt.from(10000))),
          TokenAmount(tokenB, EtherAmount.inWei(BigInt.from(10000))),
        );
        expect(
          pair
              .getLiquidityMinted(
                TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(10000))),
                TokenAmount(tokenA, EtherAmount.inWei(BigInt.from(2000))),
                TokenAmount(tokenB, EtherAmount.inWei(BigInt.from(2000))),
              )
              .value,
          equals(EtherAmount.inWei(BigInt.from(2000))),
        );
      });
      test('.getLiquidityValue():!feeOn', () {
        final tokenA = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18);
        final tokenB = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18);
        final pair = Pair(
          TokenAmount(tokenA, EtherAmount.inWei(BigInt.from(1000))),
          TokenAmount(tokenB, EtherAmount.inWei(BigInt.from(1000))),
        );

        var liquidityValue = pair.getLiquidityValue(
          tokenA,
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(1000))),
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(1000))),
          null,
          false,
        );
        expect(liquidityValue.token, equals(tokenA));
        expect(liquidityValue.value.getInWei, equals(BigInt.from(1000)));

        liquidityValue = pair.getLiquidityValue(
          tokenA,
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(1000))),
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(500))),
          null,
          false,
        );
        expect(liquidityValue.token, equals(tokenA));
        expect(liquidityValue.value.getInWei, equals(BigInt.from(500)));

        liquidityValue = pair.getLiquidityValue(
          tokenB,
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(1000))),
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(1000))),
          null,
          false,
        );
        expect(liquidityValue.token, equals(tokenB));
        expect(liquidityValue.value.getInWei, equals(BigInt.from(1000)));
      });

      test('.getLiquidityValue():feeOn', () {
        final tokenA = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18);
        final tokenB = Token(ChainId.RINKEBY, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18);
        final pair = Pair(
          TokenAmount(tokenA, EtherAmount.inWei(BigInt.from(1000))),
          TokenAmount(tokenB, EtherAmount.inWei(BigInt.from(1000))),
        );
        var liquidityValue = pair.getLiquidityValue(
          tokenA,
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(1000))),
          TokenAmount(pair.liquidityToken, EtherAmount.inWei(BigInt.from(1000))),
          BigInt.from(250000),
          true,
        );

        expect(liquidityValue.token, equals(tokenA));
        expect(liquidityValue.value.getInWei, equals(BigInt.from(917)));
      });
    });
  });
}
