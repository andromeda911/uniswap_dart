import 'package:uniswap_sdk_dart/src/constants.dart';
import 'package:uniswap_sdk_dart/src/core/Pair.dart';
import 'package:uniswap_sdk_dart/src/core/token/Token.dart';
import 'package:uniswap_sdk_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/web3dart.dart';

abstract class Fetcher {
  // TODO: add cache
  static Future<Token> fetchTokenData(Web3Client web3client, int chainId, EthereumAddress address, [String symbol, String name]) async {
    var contract = DeployedContract(UniswapV2PairABI, address);
    var resp = await web3client.call(contract: contract, function: contract.function('decimals'), params: []);

    return Token(chainId, address, (resp?.first as BigInt)?.toInt(), symbol, name);
  }

  static Future<Pair> fetchPairData(Web3Client web3client, Token tokenA, Token tokenB) async {
    var tokens = tokenA.sortsBefore(tokenB) ? [tokenA, tokenB] : [tokenB, tokenA];
    var pairAddress = Pair.getAddress(tokens[0], tokens[1]);
    var contract = DeployedContract(UniswapV2PairABI, pairAddress);
    var resp = await web3client.call(contract: contract, function: contract.function('getReserves'), params: []);
    var tokenAmount0 = TokenAmount(tokens[0], EtherAmount.inWei(resp[0] as BigInt));
    var tokenAmount1 = TokenAmount(tokens[1], EtherAmount.inWei(resp[1] as BigInt));

    return Pair(tokenAmount0, tokenAmount1);
  }
}
