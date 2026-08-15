import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallet/wallet.dart' as hd;
import 'package:web3dart/web3dart.dart';

class WalletInfo {
  final String id;
  final String name;
  final String address;
  final String mnemonic;
  final bool testnet;

  const WalletInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.mnemonic,
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
    Map<String, dynamic> json,
    String mnemonic,
  ) {
    return WalletInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      mnemonic: mnemonic,
      testnet: json['testnet'] as bool,
    );
  }
}

class WalletService {
  static const String _walletsKey = 'melona_wallets';

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  Future<List<WalletInfo>> getWallets() async {
    final raw = await _storage.read(
      key: _walletsKey,
    );

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final list = jsonDecode(raw) as List;

    final wallets = <WalletInfo>[];

    for (final item in list) {
      final map = Map<String, dynamic>.from(
        item as Map,
      );

      final id = map['id'] as String;

      final mnemonic = await _storage.read(
        key: 'wallet_${id}_mnemonic',
      );

      if (mnemonic == null) {
        continue;
      }

      wallets.add(
        WalletInfo.fromJson(
          map,
          mnemonic,
        ),
      );
    }

    return wallets;
  }

  Future<void> _saveWallets(
    List<WalletInfo> wallets,
  ) async {
    final data = wallets
        .map(
          (wallet) => wallet.toJson(),
        )
        .toList();

    await _storage.write(
      key: _walletsKey,
      value: jsonEncode(data),
    );
  }

  Future<WalletInfo> createWallet({
    required String name,
    required bool testnet,
  }) async {
    final mnemonic = bip39.generateMnemonic(
      strength: 256,
    );

    return _createFromMnemonic(
      name: name,
      mnemonic: mnemonic,
      testnet: testnet,
    );
  }

  Future<WalletInfo> importWallet({
    required String name,
    required String mnemonic,
    required bool testnet,
  }) async {
    final normalized = mnemonic
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    if (!bip39.validateMnemonic(normalized)) {
      throw Exception(
        'Invalid recovery phrase',
      );
    }

    return _createFromMnemonic(
      name: name,
      mnemonic: normalized,
      testnet: testnet,
    );
  }

  Future<WalletInfo> _createFromMnemonic({
    required String name,
    required String mnemonic,
    required bool testnet,
  }) async {
    final seed = hd.mnemonicToSeed(
      mnemonic,
    );

    final master = hd.ExtendedPrivateKey.master(
      seed,
      hd.xprv,
    );

    final root = master.forPath(
      "m/44'/60'/0'/0/0",
    );

    final extended = root as hd.ExtendedPrivateKey;

    final privateKey = hd.PrivateKey(
      extended.key,
    );

    final privateKeyHex =
        _bytesToHex(privateKey.bytes);

    final credentials =
        EthPrivateKey.fromHex(
      privateKeyHex,
    );

    final address =
        credentials.address.eip55With0x;

    final id =
        DateTime.now().microsecondsSinceEpoch.toString();

    final wallet = WalletInfo(
      id: id,
      name: name,
      address: address,
      mnemonic: mnemonic,
      testnet: testnet,
    );

    final wallets = await getWallets();

    wallets.add(wallet);

    await _saveWallets(wallets);

    await _storage.write(
      key: 'wallet_${id}_mnemonic',
      value: mnemonic,
    );

    await _storage.write(
      key: 'wallet_${id}_private_key',
      value: privateKeyHex,
    );

    return wallet;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map(
          (byte) => byte
              .toRadixString(16)
              .padLeft(2, '0'),
        )
        .join();
  }

  Future<String?> getPrivateKey(
    String walletId,
  ) async {
    return _storage.read(
      key: 'wallet_${walletId}_private_key',
    );
  }

  Future<String?> getMnemonic(
    String walletId,
  ) async {
    return _storage.read(
      key: 'wallet_${walletId}_mnemonic',
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
      key: 'wallet_${walletId}_mnemonic',
    );

    await _storage.delete(
      key: 'wallet_${walletId}_private_key',
    );
  }
}
