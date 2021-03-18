import 'package:web3dart/web3dart.dart';

import 'Token.dart';

class TokenAmount {
  Token token;
  EtherAmount amount;
  TokenAmount(this.token, this.amount);
}
