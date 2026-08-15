import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'wallet_service.dart';
import 'blockchain_service.dart';

const Color melonaGreen = Color(0xFF7BE56B);

class MelonaWalletApp extends StatelessWidget {
  const MelonaWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Melona Wallet',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: melonaGreen,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080C0A),
      ),
      home: const WalletHomePage(),
    );
  }
}

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  final WalletService walletService = WalletService();
  final BlockchainService blockchainService = BlockchainService();

  List<WalletInfo> wallets = [];
  WalletInfo? selectedWallet;

  ChainConfig selectedChain = BlockchainService.ethereumSepolia;

  bool loading = true;
  String balance = '0';

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final result = await walletService.getWallets();

    if (!mounted) return;

    setState(() {
      wallets = result;
      selectedWallet = result.isEmpty ? null : result.first;
      loading = false;
    });

    if (selectedWallet != null) {
      await _refreshBalance();
    }
  }

  Future<void> _refreshBalance() async {
    if (selectedWallet == null) return;

    try {
      final amount = await blockchainService.getNativeBalance(
        chain: selectedChain,
        address: selectedWallet!.address,
      );

      if (!mounted) return;

      setState(() {
        balance = amount
            .getValueInUnit(EtherUnit.ether)
            .toStringAsFixed(6);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        balance = '0';
      });
    }
  }

  Future<void> _createWallet() async {
    final nameController = TextEditingController();

    bool testnet = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Wallet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Wallet name',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    value: testnet,
                    onChanged: (value) {
                      setDialogState(() {
                        testnet = value;
                      });
                    },
                    title: const Text('Testnet'),
                    subtitle: Text(
                      testnet
                          ? 'Safe for testing'
                          : 'Real blockchain assets',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    final wallet = await walletService.createWallet(
                      name: name,
                      testnet: testnet,
                    );

                    if (!context.mounted) return;

                    Navigator.pop(context, true);

                    await _showMnemonic(wallet);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadWallets();
    }
  }

  Future<void> _importWallet() async {
    final nameController = TextEditingController();
    final phraseController = TextEditingController();

    bool testnet = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Import Wallet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Wallet name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phraseController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Recovery phrase',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: testnet,
                      onChanged: (value) {
                        setDialogState(() {
                          testnet = value;
                        });
                      },
                      title: const Text('Testnet'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      final wallet = await walletService.importWallet(
                        name: nameController.text.trim(),
                        mnemonic: phraseController.text,
                        testnet: testnet,
                      );

                      if (!context.mounted) return;

                      Navigator.pop(context, true);

                      await _loadWallets();

                      if (mounted) {
                        await _showWallet(wallet);
                      }
                    } catch (_) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid recovery phrase'),
                        ),
                      );
                    }
                  },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadWallets();
    }
  }

  Future<void> _showMnemonic(WalletInfo wallet) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup your recovery phrase'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write these words down offline. Never send them to anyone.',
                ),
                const SizedBox(height: 20),
                SelectableText(
                  wallet.mnemonic,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I saved it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWallet(WalletInfo wallet) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                wallet.testnet ? 'TESTNET' : 'MAINNET',
                style: TextStyle(
                  color: wallet.testnet ? melonaGreen : Colors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Address',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SelectableText(wallet.address),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: wallet.address),
                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Address copied'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReceive(wallet);
                      },
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text('Receive'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showMnemonic(wallet);
                },
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Show recovery phrase'),
              ),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);

                  await walletService.deleteWallet(wallet.id);

                  await _loadWallets();
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete wallet'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReceive(WalletInfo wallet) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Receive'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: wallet.address,
                size: 220,
              ),
              const SizedBox(height: 16),
              SelectableText(
                wallet.address,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: wallet.address),
                );

                Navigator.pop(context);
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendNative() async {
    if (selectedWallet == null) return;

    final addressController = TextEditingController();
    final amountController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Send ${selectedChain.symbol}'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient address',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      sending ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final address =
                              addressController.text.trim();

                          final amount =
                              double.tryParse(
                            amountController.text.trim(),
                          );

                          if (amount == null || amount <= 0) {
                            return;
                          }

                          setDialogState(() {
                            sending = true;
                          });

                          try {
                            final privateKey =
                                await walletService.getPrivateKey(
                              selectedWallet!.id,
                            );

                            if (privateKey == null) {
                              throw Exception(
                                'Private key unavailable',
                              );
                            }

                            final wei = BigInt.from(
                              amount *
                                  1000000000000000000,
                            );

                            final hash =
                                await blockchainService.sendNative(
                              chain: selectedChain,
                              privateKey: privateKey,
                              to: address,
                              amountWei: wei,
                            );

                            if (!context.mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Transaction sent: $hash',
                                ),
                              ),
                            );

                            await _refreshBalance();
                          } catch (e) {
                            setDialogState(() {
                              sending = false;
                            });

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Transaction failed: $e',
                                ),
                              ),
                            );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Melona',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'create') {
                _createWallet();
              } else if (value == 'import') {
                _importWallet();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'create',
                child: Text('Create wallet'),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text('Import wallet'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBalance,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (selectedWallet == null)
              _EmptyWalletCard(
                onCreate: _createWallet,
                onImport: _importWallet,
              )
            else ...[
              _WalletCard(
                wallet: selectedWallet!,
                balance: balance,
                chain: selectedChain,
              ),
              const SizedBox(height: 16),
              _ChainSelector(
                selected: selectedChain,
                onChanged: (chain) async {
                  setState(() {
                    selectedChain = chain;
                  });

                  await _refreshBalance();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.arrow_upward_rounded,
                      title: 'Send',
                      onTap: _sendNative,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.arrow_downward_rounded,
                      title: 'Receive',
                      onTap: () => _showReceive(selectedWallet!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.swap_vert_rounded,
                      title: 'Swap',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Swap engine will be connected next.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'My Wallets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...wallets.map(
                (wallet) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: melonaGreen,
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(wallet.name),
                    subtitle: Text(
                      '${wallet.address.substring(0, 8)}...'
                      '${wallet.address.substring(wallet.address.length - 6)}',
                    ),
                    trailing: wallet.id == selectedWallet!.id
                        ? const Icon(
                            Icons.check_circle,
                            color: melonaGreen,
                          )
                        : null,
                    onTap: () async {
                      setState(() {
                        selectedWallet = wallet;
                      });

                      await _refreshBalance();
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final WalletInfo wallet;
  final String balance;
  final ChainConfig chain;

  const _WalletCard({
    required this.wallet,
    required this.balance,
    required this.chain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF243D2A),
            Color(0xFF101710),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: melonaGreen,
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                wallet.testnet ? 'TESTNET' : 'MAINNET',
                style: TextStyle(
                  color: wallet.testnet
                      ? melonaGreen
                      : Colors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Balance',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 5),
          Text(
            '$balance ${chain.symbol}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            wallet.address,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainSelector extends StatelessWidget {
  final ChainConfig selected;
  final ValueChanged<ChainConfig> onChanged;

  const _ChainSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chains = [
      BlockchainService.ethereumSepolia,
      BlockchainService.bnbTestnet,
      BlockchainService.polygonAmoy,
      BlockchainService.baseSepolia,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ChainConfig>(
            value: selected,
            isExpanded: true,
            items: chains
                .map(
                  (chain) => DropdownMenuItem(
                    value: chain,
                    child: Text(chain.name),
                  ),
                )
                .toList(),
            onChanged: (chain) {
              if (chain != null) {
                onChanged(chain);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF141A16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: melonaGreen,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWalletCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onImport;

  const _EmptyWalletCard({
    required this.onCreate,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF141A16),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 70,
            color: melonaGreen,
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to Melona Wallet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create a new wallet or import an existing one.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCreate,
              child: const Text('Create New Wallet'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onImport,
              child: const Text('Import Wallet'),
            ),
          ),
        ],
      ),
    );
  }
}
