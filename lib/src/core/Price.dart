import 'package:decimal/decimal.dart';

import 'currency/Currency.dart';

class Price {
  Currency baseCurrency;
  Currency quoteCurrency;
  Decimal price;

  Price(this.baseCurrency, this.quoteCurrency, this.price);

  @override
  bool operator ==(Object other) {
    if (other is Price) {
      return baseCurrency == other.baseCurrency && quoteCurrency == other.quoteCurrency && price == other.price;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => baseCurrency.hashCode ^ quoteCurrency.hashCode ^ price.hashCode;
}
