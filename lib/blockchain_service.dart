import 'dart:convert';

import 'package:http/http.dart' as http;

class ChainConfig {
  final String name;
  final String symbol;
  final int chainId;
  final String rpc;

  const ChainConfig({
    required this.name,
    required this.symbol,
    required this.chainId,
    required this.rpc,
  });
}

class BlockchainService {
  static const ethereumSepolia = ChainConfig(
    name: 'Ethereum Sepolia',
    symbol: 'ETH',
    chainId: 11155111,
    rpc: 'https://ethereum-sepolia-rpc.publicnode.com',
  );

  static const bnbTestnet = ChainConfig(
    name: 'BNB Smart Chain Testnet',
    symbol: 'tBNB',
    chainId: 97,
    rpc: 'https://bsc-testnet-rpc.publicnode.com',
  );

  static const polygonAmoy = ChainConfig(
    name: 'Polygon Amoy',
    symbol: 'POL',
    chainId: 80002,
    rpc: 'https://rpc-amoy.polygon.technology',
  );

  static const baseSepolia = ChainConfig(
    name: 'Base Sepolia',
    symbol: 'ETH',
    chainId: 84532,
    rpc: 'https://sepolia.base.org',
  );

  Future<dynamic> _rpc(
    ChainConfig chain,
    String method,
    List<dynamic> params,
  ) async {
    final response = await http.post(
      Uri.parse(chain.rpc),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': DateTime.now()
            .millisecondsSinceEpoch,
        'method': method,
        'params': params,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'RPC HTTP ${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded['error'] != null) {
      throw Exception(
        decoded['error'].toString(),
      );
    }

    return decoded['result'];
  }

  Future<BigInt> getNativeBalance({
    required ChainConfig chain,
    required String address,
  }) async {
    final result = await _rpc(
      chain,
      'eth_getBalance',
      [
        address,
        'latest',
      ],
    );

    if (result is! String) {
      return BigInt.zero;
    }

    return _hexToBigInt(result);
  }

  Future<BigInt> getGasPrice({
    required ChainConfig chain,
  }) async {
    final result = await _rpc(
      chain,
      'eth_gasPrice',
      [],
    );

    if (result is! String) {
      return BigInt.zero;
    }

    return _hexToBigInt(result);
  }

  Future<int> getChainId(
    ChainConfig chain,
  ) async {
    final result = await _rpc(
      chain,
      'eth_chainId',
      [],
    );

    if (result is! String) {
      return chain.chainId;
    }

    return _hexToBigInt(result).toInt();
  }

  Future<bool> isAddressValid(
    String address,
  ) async {
    if (address.isEmpty) {
      return false;
    }

    if (!address.startsWith('0x')) {
      return false;
    }

    if (address.length != 42) {
      return false;
    }

    final hex =
        address.substring(2);

    return RegExp(
      r'^[0-9a-fA-F]{40}$',
    ).hasMatch(hex);
  }

  BigInt _hexToBigInt(
    String value,
  ) {
    var clean = value.trim();

    if (clean.startsWith('0x') ||
        clean.startsWith('0X')) {
      clean = clean.substring(2);
    }

    if (clean.isEmpty) {
      return BigInt.zero;
    }

    return BigInt.parse(
      clean,
      radix: 16,
    );
  }

  String weiToEther(
    BigInt wei,
  ) {
    const base =
        1000000000000000000;

    final baseBig =
        BigInt.from(base);

    final whole =
        wei ~/ baseBig;

    final remainder =
        wei % baseBig;

    if (remainder == BigInt.zero) {
      return whole.toString();
    }

    var fraction =
        remainder.toString().padLeft(
              18,
              '0',
            );

    fraction =
        fraction.replaceFirst(
      RegExp(r'0+$'),
      '',
    );

    return '$whole.$fraction';
  }

  BigInt etherToWei(
    String value,
  ) {
    final input =
        value.trim();

    if (input.isEmpty) {
      return BigInt.zero;
    }

    final parts =
        input.split('.');

    final whole =
        BigInt.tryParse(
              parts[0],
            ) ??
            BigInt.zero;

    var fraction =
        parts.length > 1
            ? parts[1]
            : '';

    if (fraction.length > 18) {
      fraction =
          fraction.substring(0, 18);
    }

    fraction =
        fraction.padRight(
      18,
      '0',
    );

    final fractionValue =
        fraction.isEmpty
            ? BigInt.zero
            : BigInt.parse(fraction);

    const base =
        1000000000000000000;

    return whole *
            BigInt.from(base) +
        fractionValue;
  }

  Future<String> getBlockNumber(
    ChainConfig chain,
  ) async {
    final result = await _rpc(
      chain,
      'eth_blockNumber',
      [],
    );

    if (result is! String) {
      return '0';
    }

    return _hexToBigInt(
      result,
    ).toString();
  }
}
