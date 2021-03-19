import 'package:decimal/decimal.dart';

import 'Currency.dart';

class Price {
  Currency baseCurrency;
  Currency quoteCurrency;
  Decimal price;

  Price(this.baseCurrency, this.quoteCurrency, this.price);
}
