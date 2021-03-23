import '../currency/CurrencyAmount.dart';
import 'package:web3dart/web3dart.dart';

import 'Token.dart';

class TokenAmount extends CurrencyAmount {
  Token token;
  TokenAmount(this.token, EtherAmount value) : super(token, value);

  @override
  bool operator ==(covariant TokenAmount other) {
    return currency == other.currency && value == other.value;
  }

  @override
  int get hashCode => token.hashCode ^ value.hashCode;

  @override
  TokenAmount operator +(covariant TokenAmount other) {
    return TokenAmount(token, EtherAmount.inWei(value.getInWei + other.value.getInWei));
  }

  @override
  TokenAmount operator -(covariant TokenAmount other) {
    return TokenAmount(token, EtherAmount.inWei(value.getInWei - other.value.getInWei));
  }
}
