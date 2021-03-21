import 'package:uniswap_dart/src/core/currency/Currency.dart';
import 'package:web3dart/web3dart.dart';

import '../../constants.dart';

class CurrencyAmount {
  Currency currency;
  EtherAmount value;
  CurrencyAmount(this.currency, this.value);

  CurrencyAmount.ether(this.value) {
    currency = ETHER;
  }

  @override
  bool operator ==(covariant CurrencyAmount other) {
    return currency == other.currency && value == other.value;
  }

  @override
  int get hashCode => currency.hashCode ^ value.hashCode;

  CurrencyAmount operator +(CurrencyAmount other) {
    return CurrencyAmount(currency, EtherAmount.inWei(value.getInWei + other.value.getInWei));
  }

  CurrencyAmount operator -(CurrencyAmount other) {
    return CurrencyAmount(currency, EtherAmount.inWei(value.getInWei - other.value.getInWei));
  }
}
