import 'dart:developer';

import 'package:uniswap_dart/src/constants.dart';
import 'package:uniswap_dart/src/core/Currency.dart';

import 'Pair.dart';
import 'Price.dart';
import 'Token.dart';

class Route {
  List<Pair> pairs;
  List<Token> path;
  Currency input;
  Currency output;

  Route(this.pairs, this.input, [this.output]) {
    assert(pairs.isNotEmpty);

    final chainId = pairs.first.chainId;

    assert(pairs.every((pair) => pair.chainId == chainId));

    final weth = WETH9[chainId];

    assert((input is Token && pairs.first.involvesToken(input)) || (input == Currency.ETHER && pairs.first.involvesToken(input)));
    assert(output == null || (output is Token && pairs.last.involvesToken(output)) || (output == Currency.ETHER && pairs.last.involvesToken(output)));

    path = <Token>[input is Token ? input : weth];

    pairs.forEachIndexed((pair, i) {
      var currentInput = path[i];
      assert(currentInput == pair.token0 || currentInput == pair.token1);

      var output = currentInput == pair.token0 ? pair.token1 : pair.token0;

      path.add(output);
    });

    output ??= path.last;
  }

  int get chainId => pairs.first.chainId;

  Price midPrice() {
    var prices = <Price>[];
    pairs.forEachIndexed((pair, i) {
      prices.add(path[i] == pair.token0 ? Price(pair.reserve0.token) : Price());
    });
  }
}
