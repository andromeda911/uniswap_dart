import 'package:test/test.dart';
import 'package:uniswap_dart/src/constants.dart';
import 'package:uniswap_dart/src/core/Pair.dart';
import 'package:uniswap_dart/src/core/Route.dart';
import 'package:uniswap_dart/src/core/token/Token.dart';
import 'package:uniswap_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  group('Route', () {
    final token0 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18, 't0');
    final token1 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18, 't1');
    final weth = WETH9[ChainId.MAINNET];

    final pair_0_1 = Pair(
      TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))),
      TokenAmount(token1, EtherAmount.inWei(BigInt.from(200))),
    );
    final pair_0_weth = Pair(
      TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))),
      TokenAmount(weth, EtherAmount.inWei(BigInt.from(100))),
    );
    final pair_1_weth = Pair(
      TokenAmount(token1, EtherAmount.inWei(BigInt.from(175))),
      TokenAmount(weth, EtherAmount.inWei(BigInt.from(100))),
    );

    test('constructs a path from the tokens', () {
      final route = Route([pair_0_1], token0);
      expect(route.pairs, equals([pair_0_1]));
      expect(route.path, equals([token0, token1]));
      expect(route.input, equals(token0));
      expect(route.output, equals(token1));
      expect(route.chainId, equals(ChainId.MAINNET));
    });
    test('can have a token as both input and output', () {
      final route = Route([pair_0_weth, pair_0_1, pair_1_weth], weth);
      expect(route.pairs, equals([pair_0_weth, pair_0_1, pair_1_weth]));
      expect(route.input, equals(weth));
      expect(route.output, equals(weth));
    });
    test('supports ether input', () {
      final route = Route([pair_0_weth], ETHER);
      expect(route.pairs, equals([pair_0_weth]));
      expect(route.input, equals(ETHER));
      expect(route.output, equals(token0));
    });
    test('supports ether output', () {
      final route = Route([pair_0_weth], token0, ETHER);
      expect(route.pairs, equals([pair_0_weth]));
      expect(route.input, equals(token0));
      expect(route.output, equals(ETHER));
    });
  });
}
