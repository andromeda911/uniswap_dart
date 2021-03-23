class Currency {
  int decimals;
  String symbol;
  String name;
  Currency(
    this.decimals,
    this.symbol,
    this.name,
  );

  @override
  bool operator ==(Object other) {
    if (other is Currency) {
      return decimals == other.decimals && symbol == other.symbol && name == other.name;
    } else if (other) {
      return false;
    }
  }

  @override
  int get hashCode => decimals.hashCode ^ symbol.hashCode ^ name.hashCode;

  static final Currency ETHER = Currency(18, 'ETH', 'Ether');
}
