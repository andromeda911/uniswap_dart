import 'dart:math';

import 'package:test/test.dart';
import 'package:uniswap_sdk_dart/src/constants.dart';

void main() {
  group('babylonianSqrt()', () {
    test('correct for 0-1000', () {
      for (var i = 0; i < 1000; i++) {
        expect(babylonianSqrt(BigInt.from(i)), equals(BigInt.from(sqrt(i).floor())));
      }
    });
  });
}
