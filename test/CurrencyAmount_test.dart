import 'package:test/test.dart';
import 'package:uniswap_sdk_dart/src/core/currency/CurrencyAmount.dart';
import 'package:uniswap_sdk_dart/src/core/token/Token.dart';
import 'package:uniswap_sdk_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/web3dart.dart';
import 'package:uniswap_sdk_dart/src/constants.dart';

void main() {
  final ADDRESS_ONE = EthereumAddress.fromHex('0x0000000000000000000000000000000000000001');

  group('CurrencyAmount', () {
    group('constructor', () {
      test('works', () {
        final token = Token(ChainId.MAINNET, ADDRESS_ONE, 18);

        final amount = TokenAmount(token, EtherAmount.inWei(BigInt.from(100)));

        expect(amount.raw.getInWei, equals(BigInt.from(100)));
      });
    });
    group('.ether', () {
      test('produces ether amount', () {
        final amount = CurrencyAmount.ether(EtherAmount.inWei(BigInt.from(100)));

        expect(amount.raw.getInWei, equals(BigInt.from(100)));
      });
    });

    test('token amount can be max uint256', () {
      final amount = TokenAmount(Token(ChainId.MAINNET, ADDRESS_ONE, 18), EtherAmount.inWei(MaxUint256));
      expect(amount.raw.getInWei, MaxUint256);
    });
  });
}
