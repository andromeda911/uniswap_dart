import '../currency/CurrencyAmount.dart';
import 'package:web3dart/web3dart.dart';

import 'Token.dart';

class TokenAmount extends CurrencyAmount {
  Token token;
  TokenAmount(this.token, EtherAmount raw) : super(token, raw);

  @override
  bool operator ==(covariant TokenAmount other) {
    return currency == other.currency && value == other.value;
  }

  @override
  int get hashCode => token.hashCode ^ value.hashCode;

  @override
  TokenAmount operator +(covariant TokenAmount other) {
    return TokenAmount(token, EtherAmount.inWei(raw.getInWei + other.raw.getInWei));
  }

  @override
  TokenAmount operator -(covariant TokenAmount other) {
    return TokenAmount(token, EtherAmount.inWei(raw.getInWei - other.raw.getInWei));
  }

  @override
  String toString() {
    return '${token.symbol}, ${raw.getInWei}';
  }
}
