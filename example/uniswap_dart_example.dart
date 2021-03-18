import 'package:uniswap_dart/src/Fetcher.dart';
import 'package:uniswap_dart/src/constants.dart';
import 'package:uniswap_dart/src/core/Pair.dart';
import 'package:uniswap_dart/src/core/Token.dart';
import 'package:web3dart/credentials.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

void main() async {
  var dai = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x6B175474E89094C44Da98b954EedeAC495271d0F'), 18);
  var weth = WETH9[ChainId.MAINNET];
  var pairAddress = computePairAddress(FACTORY_ADDRESS, dai, weth);

  var url = 'https://mainnet.infura.io/v3/919239cfe05943f38c7c16434c4e100e';
  var w3client = Web3Client(url, http.Client());

  var token = await Fetcher.fetchTokenData(w3client, ChainId.MAINNET, dai.address);
  print(token.decimals);

  var pair = await Fetcher.fetchPairData(w3client, dai, weth);
  print(pair.reserve0.amount.getInEther);
  print(pair.reserve1.amount.getInEther);
}
