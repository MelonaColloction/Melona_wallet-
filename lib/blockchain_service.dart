import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

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

  Web3Client _client(ChainConfig chain) {
    return Web3Client(
      chain.rpc,
      http.Client(),
    );
  }

  Future<BigInt> getNativeBalance({
    required ChainConfig chain,
    required String address,
  }) async {
    final client = _client(chain);

    try {
      final result = await client.makeRPCCall(
        'eth_getBalance',
        [
          address,
          'latest',
        ],
      );

      if (result is List && result.isNotEmpty) {
        final value = result.first;

        if (value is String) {
          return BigInt.parse(
            value.replaceFirst(
              '0x',
              '',
            ),
            radix: 16,
          );
        }
      }

      if (result is String) {
        return BigInt.parse(
          result.replaceFirst(
            '0x',
            '',
          ),
          radix: 16,
        );
      }

      return BigInt.zero;
    } finally {
      client.dispose();
    }
  }

  Future<String> sendNative({
    required ChainConfig chain,
    required String privateKey,
    required String to,
    required BigInt amountWei,
  }) async {
    final client = _client(chain);

    try {
      final credentials =
          EthPrivateKey.fromHex(
        privateKey,
      );

      final transaction = Transaction(
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.fromBigInt(
          EtherUnit.wei,
          amountWei,
        ),
      );

      return await client.sendTransaction(
        credentials,
        transaction,
        chainId: chain.chainId,
      );
    } finally {
      client.dispose();
    }
  }

  Future<BigInt> getGasPrice({
    required ChainConfig chain,
  }) async {
    final client = _client(chain);

    try {
      final result = await client.makeRPCCall(
        'eth_gasPrice',
        [],
      );

      if (result is List && result.isNotEmpty) {
        final value = result.first;

        if (value is String) {
          return BigInt.parse(
            value.replaceFirst(
              '0x',
              '',
            ),
            radix: 16,
          );
        }
      }

      if (result is String) {
        return BigInt.parse(
          result.replaceFirst(
            '0x',
            '',
          ),
          radix: 16,
        );
      }

      return BigInt.zero;
    } finally {
      client.dispose();
    }
  }

  Future<int> getChainId(
    ChainConfig chain,
  ) async {
    final client = _client(chain);

    try {
      final result = await client.makeRPCCall(
        'eth_chainId',
        [],
      );

      if (result is List && result.isNotEmpty) {
        final value = result.first;

        if (value is String) {
          return int.parse(
            value.replaceFirst(
              '0x',
              '',
            ),
            radix: 16,
          );
        }
      }

      if (result is String) {
        return int.parse(
          result.replaceFirst(
            '0x',
            '',
          ),
          radix: 16,
        );
      }

      return chain.chainId;
    } finally {
      client.dispose();
    }
  }

  Future<bool> isAddressValid(
    String address,
  ) async {
    try {
      EthereumAddress.fromHex(
        address,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  String weiToEther(
    BigInt wei,
  ) {
    final whole = wei ~/ BigInt.from(1000000000000000000);
    final fraction =
        wei % BigInt.from(1000000000000000000);

    final fractionText = fraction
        .toString()
        .padLeft(18, '0');

    final trimmed = fractionText
        .replaceFirst(RegExp(r'0+$'), '');

    if (trimmed.isEmpty) {
      return whole.toString();
    }

    return '$whole.$trimmed';
  }

  BigInt etherToWei(
    String value,
  ) {
    final parts = value.split('.');

    final whole = BigInt.parse(
      parts.first,
    );

    String fraction =
        parts.length > 1
            ? parts[1]
            : '';

    fraction = fraction.padRight(
      18,
      '0',
    );

    if (fraction.length > 18) {
      fraction =
          fraction.substring(0, 18);
    }

    final fractional =
        fraction.isEmpty
            ? BigInt.zero
            : BigInt.parse(fraction);

    return whole *
            BigInt.from(
              1000000000000000000,
            ) +
        fractional *
            BigInt.from(
              10,
            ).pow(
              18 - fraction.length,
            );
  }

  String encodeJson(
    Map<String, dynamic> data,
  ) {
    return jsonEncode(data);
  }
}
