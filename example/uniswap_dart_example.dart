import 'package:decimal/decimal.dart';
import 'package:uniswap_dart/src/Fetcher.dart';
import 'package:uniswap_dart/src/constants.dart';
import 'package:uniswap_dart/src/core/Trade.dart';
import 'package:uniswap_dart/src/core/currency/Currency.dart';
import 'package:uniswap_dart/src/core/Pair.dart';
import 'package:uniswap_dart/src/core/Route.dart';
import 'package:uniswap_dart/src/core/token/Token.dart';
import 'package:uniswap_dart/src/core/token/TokenAmount.dart';
import 'package:web3dart/credentials.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'dart:convert';

void main() async {
  //var dai = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x6B175474E89094C44Da98b954EedeAC495271d0F'), 18);
  //var dd = Currency(18, 'dai', 'dda');
  //print(dd is Token);
  var token0 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'), 18, 't0');
  var token1 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'), 18, 't1');
  var token2 = Token(ChainId.MAINNET, EthereumAddress.fromHex('0x0000000000000000000000000000000000000003'), 18, 't2');

  var pair_0_1 = Pair(TokenAmount(token0, EtherAmount.inWei(BigInt.from(1000))), TokenAmount(token1, EtherAmount.inWei(BigInt.from(1000))));
  var pair_1_2 = Pair(TokenAmount(token1, EtherAmount.inWei(BigInt.from(1200))), TokenAmount(token2, EtherAmount.inWei(BigInt.from(1000))));

  //var exactIn = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token0, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_INPUT);
  var exactOut = Trade(Route([pair_0_1, pair_1_2], token0), TokenAmount(token2, EtherAmount.inWei(BigInt.from(100))), TradeType.EXACT_OUTPUT);

  //print(exactIn.minimumAmountOut(Decimal.parse('200')).value.getInWei);

  print(exactOut.minimumAmountOut(Decimal.parse('5')) == exactOut.outputAmount);

  //var usdc = Token(ChainId.MAINNET, EthereumAddress.fromHex('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'), 6);
  //var weth = WETH9[ChainId.MAINNET];

  //var url = 'https://mainnet.infura.io/v3/919239cfe05943f38c7c16434c4e100e';
  //var w3client = Web3Client(url, http.Client());

  //var pairUSDC_WETH = await Fetcher.fetchPairData(w3client, usdc, weth);
  //var pairDAI_USDC = await Fetcher.fetchPairData(w3client, dai, usdc);

  //var route = Route([pairUSDC_WETH, pairDAI_USDC], weth);

  //print(route.midPrice().price);
  //print(route.midPrice().price.inverse);
}

// import { Contract } from "@ethersproject/contracts";
// import {
//   getDefaultProvider,
//   getNetwork,
//   InfuraProvider
// } from "@ethersproject/providers";
// import { Token, ChainId, Pair, Route, WETH, TokenAmount } from "@uniswap/sdk";
// const chainId = ChainId.MAINNET;
// const tokenAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; // must be checksummed
// const decimals = 18;
// const weth = WETH[chainId];
// const DAI = new Token(chainId, tokenAddress, decimals);
// const USDC = new Token(
//   chainId,
//   "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
//   6
// );

// const init = async () => {
//   //const pairAddress = Pair.getAddress(DAI, WETH[DAI.chainId]);

//   var provider = new InfuraProvider(null, "919239cfe05943f38c7c16434c4e100e");

//   var pairAbi =
//     '[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount0","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amount1","type":"uint256"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"Burn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount0","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amount1","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount0In","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amount1In","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amount0Out","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amount1Out","type":"uint256"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"Swap","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint112","name":"reserve0","type":"uint112"},{"indexed":false,"internalType":"uint112","name":"reserve1","type":"uint112"}],"name":"Sync","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"MINIMUM_LIQUIDITY","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"to","type":"address"}],"name":"burn","outputs":[{"internalType":"uint256","name":"amount0","type":"uint256"},{"internalType":"uint256","name":"amount1","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"factory","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getReserves","outputs":[{"internalType":"uint112","name":"_reserve0","type":"uint112"},{"internalType":"uint112","name":"_reserve1","type":"uint112"},{"internalType":"uint32","name":"_blockTimestampLast","type":"uint32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_token0","type":"address"},{"internalType":"address","name":"_token1","type":"address"}],"name":"initialize","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"kLast","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"to","type":"address"}],"name":"mint","outputs":[{"internalType":"uint256","name":"liquidity","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"price0CumulativeLast","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"price1CumulativeLast","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"to","type":"address"}],"name":"skim","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"amount0Out","type":"uint256"},{"internalType":"uint256","name":"amount1Out","type":"uint256"},{"internalType":"address","name":"to","type":"address"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"swap","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"sync","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"token0","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"token1","outputs":[{"internalType":"address","name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]';
//   //var contract = new Contract(pairAddress, pairAbi, provider);
//   // const reserves = await contract.getReserves();

//   // //const reserves = [];
//   // const [reserve0, reserve1] = reserves;

//   // const tokens = [DAI, WETH[DAI.chainId]];
//   // const [token0, token1] = tokens[0].sortsBefore(tokens[1])
//   //   ? tokens
//   //   : [tokens[1], tokens[0]];

//   // const pair = new Pair(
//   //   new TokenAmount(token0, reserve0),
//   //   new TokenAmount(token1, reserve1)
//   // );

//   var tokens_p_0 = [USDC, weth];
//   var USDC_WETH_address = Pair.getAddress(tokens_p_0[0], tokens_p_0[1]);
//   var contractUSDC_WETH = new Contract(USDC_WETH_address, pairAbi, provider);
//   const [reserve_0_0, reserve_0_1] = await contractUSDC_WETH.getReserves();
//   const [token_0_0, token_0_1] = tokens_p_0[0].sortsBefore(tokens_p_0[1])
//     ? tokens_p_0
//     : tokens_p_0.reverse();
//   const USDCWETHPair = new Pair(
//     new TokenAmount(token_0_0, reserve_0_0),
//     new TokenAmount(token_0_1, reserve_0_1)
//   );

//   var tokens_p_1 = [DAI, USDC];
//   var DAI_USDC_address = Pair.getAddress(tokens_p_1[0], tokens_p_1[1]);
//   var contractDAI_USDC = new Contract(DAI_USDC_address, pairAbi, provider);
//   const [reserve_1_0, reserve_1_1] = await contractDAI_USDC.getReserves();
//   const [token_1_0, token_1_1] = tokens_p_1[0].sortsBefore(tokens_p_1[1])
//     ? tokens_p_1
//     : tokens_p_1.reverse();
//   const DAIUSDCPair = new Pair(
//     new TokenAmount(token_1_0, reserve_1_0),
//     new TokenAmount(token_1_1, reserve_1_1)
//   );

//   const route = new Route([USDCWETHPair, DAIUSDCPair], weth);

//   console.log(route.midPrice.toSignificant(6));
//   console.log(route.midPrice.invert().toSignificant(6));
//   //  var route = new Route([pair], WETH[DAI.chainId]);
// };
// //init();
