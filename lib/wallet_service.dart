import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

class WalletInfo {
  final String id;
  final String name;
  final String address;
  final String privateKey;
  final bool testnet;

  const WalletInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.privateKey,
    required this.testnet,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'testnet': testnet,
    };
  }

  factory WalletInfo.fromJson(
    Map<String, dynamic> json, {
    required String privateKey,
  }) {
    return WalletInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      privateKey: privateKey,
      testnet: json['testnet'] as bool? ?? true,
    );
  }
}

class WalletService {
  static const String _walletsKey = 'melona_wallets';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  Future<List<WalletInfo>> getWallets() async {
    final raw = await _storage.read(
      key: _walletsKey,
    );

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return [];
    }

    final result = <WalletInfo>[];

    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);

      final id = map['id']?.toString();

      if (id == null || id.isEmpty) {
        continue;
      }

      final privateKey =
          await _storage.read(
        key: 'wallet_${id}_private_key',
      );

      if (privateKey == null ||
          privateKey.isEmpty) {
        continue;
      }

      result.add(
        WalletInfo.fromJson(
          map,
          privateKey: privateKey,
        ),
      );
    }

    return result;
  }

  Future<WalletInfo> createWallet({
    required String name,
    required bool testnet,
  }) async {
    /*
     * web3dart خودش قابلیت ساخت private key
     * و Credential را دارد.
     *
     * برای این مرحله از HD/BIP44 خارجی استفاده
     * نمی‌کنیم تا dependency conflict نداشته باشیم.
     */

    final random = Random.secure();

    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    final privateKey = bytes
        .map(
          (e) => e
              .toRadixString(16)
              .padLeft(2, '0'),
        )
        .join();

    final credentials =
        EthPrivateKey.fromHex(
      privateKey,
    );

    final address =
        credentials.address.eip55With0x;

    final id =
        DateTime.now()
            .microsecondsSinceEpoch
            .toString();

    final wallet = WalletInfo(
      id: id,
      name: name,
      address: address,
      privateKey: privateKey,
      testnet: testnet,
    );

    final wallets = await getWallets();

    wallets.add(wallet);

    await _saveWallets(wallets);

    await _storage.write(
      key: 'wallet_${id}_private_key',
      value: privateKey,
    );

    return wallet;
  }

  Future<void> _saveWallets(
    List<WalletInfo> wallets,
  ) async {
    final data = wallets
        .map((wallet) => wallet.toJson())
        .toList();

    await _storage.write(
      key: _walletsKey,
      value: jsonEncode(data),
    );
  }

  Future<String?> getPrivateKey(
    String walletId,
  ) {
    return _storage.read(
      key: 'wallet_${walletId}_private_key',
    );
  }

  Future<void> deleteWallet(
    String walletId,
  ) async {
    final wallets = await getWallets();

    wallets.removeWhere(
      (wallet) => wallet.id == walletId,
    );

    await _saveWallets(wallets);

    await _storage.delete(
      key: 'wallet_${walletId}_private_key',
    );
  }
}
