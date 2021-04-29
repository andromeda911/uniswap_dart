import 'package:test/test.dart';
import 'package:uniswap_sdk_dart/src/core/token/Token.dart';
import 'package:web3dart/web3dart.dart';
import 'package:uniswap_sdk_dart/src/constants.dart';

void main() {
  group('Token', () {
    final ADDRESS_ONE = EthereumAddress.fromHex('0x0000000000000000000000000000000000000001');
    final ADDRESS_TWO = EthereumAddress.fromHex('0x0000000000000000000000000000000000000002');

    group('equals', () {
      test('false if address differs', () {
        expect(Token(ChainId.MAINNET, ADDRESS_ONE, 18) == Token(ChainId.MAINNET, ADDRESS_TWO), equals(false));
      });
      test('false if chain differs', () {
        expect(Token(ChainId.ROPSTEN, ADDRESS_ONE, 18) == Token(ChainId.MAINNET, ADDRESS_TWO), equals(false));
      });
      test('true if only decimals differs', () {
        expect(Token(ChainId.MAINNET, ADDRESS_ONE, 9) == Token(ChainId.MAINNET, ADDRESS_ONE), equals(true));
      });
      test('true if address is the same', () {
        expect(Token(ChainId.MAINNET, ADDRESS_ONE, 18) == Token(ChainId.MAINNET, ADDRESS_ONE), equals(true));
      });
      test('true on reference equality', () {
        final token = Token(ChainId.MAINNET, ADDRESS_ONE, 18);
        expect(token == token, equals(true));
      });
      test('true even if name/symbol/decimals differ', () {
        final tokenA = Token(ChainId.MAINNET, ADDRESS_ONE, 9, 'abc', 'def');
        final tokenB = Token(ChainId.MAINNET, ADDRESS_ONE, 18, 'ghi', 'jkl');
        expect(tokenA == tokenB, equals(true));
      });
    });
  });
}
