import 'package:decimal/decimal.dart';

import 'currency/Currency.dart';

class Price {
  Currency baseCurrency;
  Currency quoteCurrency;
  Decimal price;

  Price(this.baseCurrency, this.quoteCurrency, this.price);
}
