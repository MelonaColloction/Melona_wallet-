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
  static const ChainConfig ethereumSepolia = ChainConfig(
    name: 'Ethereum Sepolia',
    symbol: 'ETH',
    chainId: 11155111,
    rpc: 'https://ethereum-sepolia-rpc.publicnode.com',
  );

  static const ChainConfig bnbTestnet = ChainConfig(
    name: 'BNB Smart Chain Testnet',
    symbol: 'tBNB',
    chainId: 97,
    rpc: 'https://bsc-testnet-rpc.publicnode.com',
  );

  static const ChainConfig polygonAmoy = ChainConfig(
    name: 'Polygon Amoy',
    symbol: 'POL',
    chainId: 80002,
    rpc: 'https://rpc-amoy.polygon.technology',
  );

  static const ChainConfig baseSepolia = ChainConfig(
    name: 'Base Sepolia',
    symbol: 'ETH',
    chainId: 84532,
    rpc: 'https://sepolia.base.org',
  );

  Web3Client clientFor(ChainConfig chain) {
    return Web3Client(
      chain.rpc,
      http.Client(),
    );
  }

  Future<EtherAmount> getNativeBalance({
    required ChainConfig chain,
    required String address,
  }) async {
    final client = clientFor(chain);

    try {
      final ethereumAddress = EthereumAddress.fromHex(address);

      return await client.getBalance(ethereumAddress);
    } finally {
      await client.dispose();
    }
  }

  Future<String> sendNative({
    required ChainConfig chain,
    required String privateKey,
    required String to,
    required BigInt amountWei,
  }) async {
    final client = clientFor(chain);

    try {
      final credentials = EthPrivateKey.fromHex(privateKey);

      final recipient = EthereumAddress.fromHex(to);

      final transaction = Transaction(
        to: recipient,
        value: EtherAmount.inWei(amountWei),
      );

      final hash = await client.sendTransaction(
        credentials,
        transaction,
        chainId: chain.chainId,
      );

      return hash;
    } finally {
      await client.dispose();
    }
  }
}
