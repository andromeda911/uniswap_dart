import 'package:uniswap_dart/src/constants.dart';
import 'package:web3dart/credentials.dart';
import 'Currency.dart';

class Token extends Currency {
  int chainId;
  EthereumAddress address;
  Token(
    this.chainId,
    this.address, [
    int decimals,
    String symbol,
    String name,
  ]) : super(decimals, symbol, name);

  @override
  bool operator ==(Object other) {
    if (other is Token) {
      return chainId == other.chainId && address == other.address;
    } else {
      return false;
    }
  }

  bool sortsBefore(Token other) {
    // TODO : check chain ids and addresses: @core/token.ts:37
    return address.hex.compareTo(other.address.hex) < 0;
  }
}

/// ChainID : Token
final WETH9 = <int, Token>{
  ChainId.MAINNET: Token(
    ChainId.MAINNET,
    EthereumAddress.fromHex('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'),
    18,
    'WETH9',
    'Wrapped Ether',
  ),
  ChainId.ROPSTEN: Token(
    ChainId.ROPSTEN,
    EthereumAddress.fromHex('0xc778417E063141139Fce010982780140Aa0cD5Ab'),
    18,
    'WETH9',
    'Wrapped Ether',
  ),
  ChainId.RINKEBY: Token(
    ChainId.RINKEBY,
    EthereumAddress.fromHex('0xc778417E063141139Fce010982780140Aa0cD5Ab'),
    18,
    'WETH9',
    'Wrapped Ether',
  ),
  ChainId.GORLI: Token(
    ChainId.GORLI,
    EthereumAddress.fromHex('0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6'),
    18,
    'WETH9',
    'Wrapped Ether',
  ),
  ChainId.KOVAN: Token(
    ChainId.KOVAN,
    EthereumAddress.fromHex('0xd0A1E359811322d97991E03f863a0C30C2cF029C'),
    18,
    'WETH9',
    'Wrapped Ether',
  ),
};
