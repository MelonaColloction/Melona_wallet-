import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:dart_bip32_bip44/dart_bip32_bip44.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      'mnemonic': mnemonic,
      'testnet': testnet,
    };
  }

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      mnemonic: json['mnemonic'] as String,
      testnet: json['testnet'] as bool,
    );
  }
}

class WalletService {
  static const String _walletsKey = 'melona_wallets';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<WalletInfo>> getWallets() async {
    final raw = await _storage.read(key: _walletsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List;

    return decoded
        .map(
          (item) => WalletInfo.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> _saveWallets(List<WalletInfo> wallets) async {
    final encoded = jsonEncode(
      wallets.map((wallet) => wallet.toJson()).toList(),
    );

    await _storage.write(
      key: _walletsKey,
      value: encoded,
    );
  }

  Future<WalletInfo> createWallet({
    required String name,
    required bool testnet,
  }) async {
    final mnemonic = bip39.generateMnemonic(strength: 256);

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
    final normalized = mnemonic.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (!bip39.validateMnemonic(normalized)) {
      throw Exception('Invalid recovery phrase');
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
    final seedHex = bip39.mnemonicToSeedHex(mnemonic);

    final chain = Chain.seed(seedHex);

    // BIP-44 Ethereum path.
    final privateKey = chain.forPath("m/44'/60'/0'/0/0");

    final privateKeyHex = privateKey.privateKeyHex();

    final credentials = EthPrivateKey.fromHex(privateKeyHex);

    final address = credentials.address.eip55With0x;

    final id = DateTime.now().microsecondsSinceEpoch.toString();

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

    // Store the private material separately as well.
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

  Future<void> deleteWallet(String id) async {
    final wallets = await getWallets();

    wallets.removeWhere((wallet) => wallet.id == id);

    await _saveWallets(wallets);

    await _storage.delete(
      key: 'wallet_${id}_mnemonic',
    );

    await _storage.delete(
      key: 'wallet_${id}_private_key',
    );
  }

  Future<String?> getPrivateKey(String walletId) {
    return _storage.read(
      key: 'wallet_${walletId}_private_key',
    );
  }

  Future<String?> getMnemonic(String walletId) {
    return _storage.read(
      key: 'wallet_${walletId}_mnemonic',
    );
  }
}
