import 'package:decimal/decimal.dart';
import 'package:uniswap_sdk_dart/src/core/currency/Currency.dart';
import 'package:web3dart/web3dart.dart';

import '../../constants.dart';

class CurrencyAmount {
  Currency currency;
  EtherAmount raw;
  Decimal value;
  CurrencyAmount(this.currency, this.raw) {
    assert(raw.getInWei <= MaxUint256);
    value = raw.weiToDecimalEther(currency.decimals);
  }

  static CurrencyAmount ether(EtherAmount value) {
    return CurrencyAmount(ETHER, value);
  }

  @override
  bool operator ==(covariant CurrencyAmount other) {
    return currency == other.currency && value == other.value;
  }

  @override
  int get hashCode => currency.hashCode ^ value.hashCode;

  CurrencyAmount operator +(CurrencyAmount other) {
    return CurrencyAmount(currency, EtherAmount.inWei(raw.getInWei + raw.getInWei));
  }

  CurrencyAmount operator -(CurrencyAmount other) {
    return CurrencyAmount(currency, EtherAmount.inWei(raw.getInWei - raw.getInWei));
  }
}
