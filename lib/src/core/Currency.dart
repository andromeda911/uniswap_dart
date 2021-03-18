import 'package:web3dart/credentials.dart';

class Currency {
  int decimals;
  String symbol;
  String name;
  Currency(
    this.decimals,
    this.symbol,
    this.name,
  );

  static final Currency ETHER = Currency(18, 'ETH', 'Ether');
}
