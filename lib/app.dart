import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'wallet_service.dart';
import 'blockchain_service.dart';

const melonaGreen = Color(0xFF7BE56B);

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
        scaffoldBackgroundColor:
            const Color(0xFF080C0A),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final walletService = WalletService();
  final blockchainService =
      BlockchainService();

  List<WalletInfo> wallets = [];

  WalletInfo? selectedWallet;

  ChainConfig selectedChain =
      BlockchainService.ethereumSepolia;

  String balance = '0.000000';

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result =
        await walletService.getWallets();

    if (!mounted) return;

    setState(() {
      wallets = result;
      selectedWallet =
          result.isEmpty ? null : result.first;
      loading = false;
    });

    await refreshBalance();
  }

  Future<void> refreshBalance() async {
    if (selectedWallet == null) return;

    try {
      final value =
          await blockchainService
              .getNativeBalance(
        chain: selectedChain,
        address: selectedWallet!.address,
      );

      if (!mounted) return;

      setState(() {
        balance = value
            .getValueInUnit(
              EtherUnit.ether,
            )
            .toStringAsFixed(6);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        balance = '0.000000';
      });
    }
  }

  Future<void> createWallet() async {
    final name =
        TextEditingController();

    bool testnet = true;

    final created =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title:
                  const Text('ساخت کیف پول'),
              content:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'نام کیف پول',
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SwitchListTile(
                    value: testnet,
                    onChanged:
                        (value) {
                      setDialogState(
                        () => testnet =
                            value,
                      );
                    },
                    title:
                        const Text(
                      'Testnet',
                    ),
                    subtitle:
                        Text(
                      testnet
                          ? 'مناسب برای تست'
                          : 'دارایی واقعی',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child:
                      const Text(
                    'انصراف',
                  ),
                ),
                FilledButton(
                  onPressed:
                      () async {
                    if (name.text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final wallet =
                        await walletService
                            .createWallet(
                      name: name.text
                          .trim(),
                      testnet:
                          testnet,
                    );

                    if (!dialogContext
                        .mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      true,
                    );

                    await showMnemonic(
                      wallet,
                    );
                  },
                  child:
                      const Text(
                    'ساخت',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      await load();
    }
  }

  Future<void> importWallet() async {
    final name =
        TextEditingController();

    final phrase =
        TextEditingController();

    bool testnet = true;

    final imported =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title:
                  const Text(
                'بازیابی کیف پول',
              ),
              content:
                  SingleChildScrollView(
                child:
                    Column(
                  children: [
                    TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'نام کیف پول',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: phrase,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Recovery Phrase',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SwitchListTile(
                      value: testnet,
                      onChanged:
                          (value) {
                        setDialogState(
                          () => testnet =
                              value,
                        );
                      },
                      title:
                          const Text(
                        'Testnet',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child:
                      const Text(
                    'انصراف',
                  ),
                ),
                FilledButton(
                  onPressed:
                      () async {
                    try {
                      await walletService
                          .importWallet(
                        name: name.text
                            .trim(),
                        mnemonic:
                            phrase.text,
                        testnet:
                            testnet,
                      );

                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        true,
                      );
                    } catch (_) {
                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'عبارت بازیابی معتبر نیست',
                          ),
                        ),
                      );
                    }
                  },
                  child:
                      const Text(
                    'بازیابی',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (imported == true) {
      await load();
    }
  }

  Future<void> showMnemonic(
    WalletInfo wallet,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'عبارت بازیابی',
          ),
          content:
              SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'این عبارت را روی کاغذ یادداشت کن و هرگز برای کسی ارسال نکن.',
                ),
                const SizedBox(
                  height: 20,
                ),
                SelectableText(
                  wallet.mnemonic,
                  style:
                      const TextStyle(
                    fontSize: 17,
                    height: 1.8,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              child:
                  const Text(
                'ذخیره کردم',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> receive() async {
    if (selectedWallet == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'دریافت',
          ),
          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              QrImageView(
                data:
                    selectedWallet!.address,
                size: 220,
              ),
              const SizedBox(
                height: 16,
              ),
              SelectableText(
                selectedWallet!
                    .address,
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        selectedWallet!
                            .address,
                  ),
                );

                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'کپی آدرس',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteWallet(
    WalletInfo wallet,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'حذف کیف پول',
          ),
          content:
              const Text(
            'این عملیات اطلاعات کیف پول را از دستگاه حذف می‌کند. مطمئن هستید؟',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text(
                'انصراف',
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text(
                'حذف',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await walletService
        .deleteWallet(wallet.id);

    await load();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text(
            'Melona Wallet',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected:
                  (value) {
                if (value ==
                    'create') {
                  createWallet();
                }

                if (value ==
                    'import') {
                  importWallet();
                }
              },
              itemBuilder:
                  (context) => const [
                PopupMenuItem(
                  value: 'create',
                  child:
                      Text(
                    'ساخت کیف پول',
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child:
                      Text(
                    'بازیابی کیف پول',
                  ),
                ),
              ],
            ),
          ],
        ),
        body:
            RefreshIndicator(
          onRefresh:
              refreshBalance,
          child:
              ListView(
            padding:
                const EdgeInsets.all(
              20,
            ),
            children: [
              if (selectedWallet ==
                  null)
                _EmptyWallet(
                  create:
                      createWallet,
                  import:
                      importWallet,
                )
              else ...[
                _WalletCard(
                  wallet:
                      selectedWallet!,
                  balance:
                      balance,
                  chain:
                      selectedChain,
                ),
                const SizedBox(
                  height: 16,
                ),
                _ChainDropdown(
                  selected:
                      selectedChain,
                  onChanged:
                      (chain) async {
                    setState(() {
                      selectedChain =
                          chain;
                    });

                    await refreshBalance();
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          _Action(
                        icon: Icons
                            .arrow_upward_rounded,
                        title:
                            'ارسال',
                        onTap: () {
                          ScaffoldMessenger
                              .of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content:
                                  Text(
                                'Send در مرحله بعدی متصل می‌شود.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                          _Action(
                        icon: Icons
                            .arrow_downward_rounded,
                        title:
                            'دریافت',
                        onTap:
                            receive,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                          _Action(
                        icon: Icons
                            .swap_vert_rounded,
                        title:
                            'Swap',
                        onTap: () {
                          ScaffoldMessenger
                              .of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content:
                                  Text(
                                'Swap در مرحله بعدی متصل می‌شود.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
                const Text(
                  'کیف پول‌های من',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                ...wallets.map(
                  (wallet) =>
                      Card(
                    child:
                        ListTile(
                      leading:
                          const CircleAvatar(
                        backgroundColor:
                            melonaGreen,
                        child:
                            Icon(
                          Icons
                              .account_balance_wallet,
                          color:
                              Colors.black,
                        ),
                      ),
                      title:
                          Text(
                        wallet.name,
                      ),
                      subtitle:
                          Text(
                        wallet.address,
                      ),
                      trailing:
                          Row(
                        mainAxisSize:
                            MainAxisSize
                                .min,
                        children: [
                          if (wallet.id ==
                              selectedWallet!
                                  .id)
                            const Icon(
                              Icons
                                  .check_circle,
                              color:
                                  melonaGreen,
                            ),
                          PopupMenuButton(
                            onSelected:
                                (value) {
                              if (value ==
                                  'delete') {
                                deleteWallet(
                                  wallet,
                                );
                              }

                              if (value ==
                                  'backup') {
                                showMnemonic(
                                  wallet,
                                );
                              }
                            },
                            itemBuilder:
                                (context) =>
                                    const [
                              PopupMenuItem(
                                value:
                                    'backup',
                                child:
                                    Text(
                                  'نمایش عبارت بازیابی',
                                ),
                              ),
                              PopupMenuItem(
                                value:
                                    'delete',
                                child:
                                    Text(
                                  'حذف',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () async {
                        setState(() {
                          selectedWallet =
                              wallet;
                        });

                        await refreshBalance();
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletCard
    extends StatelessWidget {
  final WalletInfo wallet;
  final String balance;
  final ChainConfig chain;

  const _WalletCard({
    required this.wallet,
    required this.balance,
    required this.chain,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(24),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(28),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF243D2A),
            Color(0xFF101710),
          ],
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor:
                    melonaGreen,
                child: Icon(
                  Icons
                      .account_balance_wallet,
                  color:
                      Colors.black,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    Text(
                  wallet.name,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              Text(
                wallet.testnet
                    ? 'TESTNET'
                    : 'MAINNET',
                style:
                    TextStyle(
                  color: wallet.testnet
                      ? melonaGreen
                      : Colors.orange,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 26,
          ),
          const Text(
            'موجودی',
            style:
                TextStyle(
              color:
                  Colors.white60,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            '$balance ${chain.symbol}',
            style:
                const TextStyle(
              fontSize: 30,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Text(
            wallet.address,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainDropdown
    extends StatelessWidget {
  final ChainConfig selected;
  final ValueChanged<ChainConfig>
      onChanged;

  const _ChainDropdown({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const chains = [
      BlockchainService
          .ethereumSepolia,
      BlockchainService.bnbTestnet,
      BlockchainService.polygonAmoy,
      BlockchainService.baseSepolia,
    ];

    return Card(
      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child:
            DropdownButtonHideUnderline(
          child:
              DropdownButton<
                  ChainConfig>(
            value:
                selected,
            isExpanded:
                true,
            items:
                chains.map(
              (chain) {
                return DropdownMenuItem(
                  value:
                      chain,
                  child:
                      Text(
                    chain.name,
                  ),
                );
              },
            ).toList(),
            onChanged:
                (chain) {
              if (chain !=
                  null) {
                onChanged(
                  chain,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _Action
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(18),
      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 18,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFF141A16),
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        child:
            Column(
          children: [
            Icon(
              icon,
              color:
                  melonaGreen,
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWallet
    extends StatelessWidget {
  final VoidCallback create;
  final VoidCallback import;

  const _EmptyWallet({
    required this.create,
    required this.import,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(28),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF141A16),
        borderRadius:
            BorderRadius.circular(28),
      ),
      child:
          Column(
        children: [
          const Icon(
            Icons
                .account_balance_wallet_rounded,
            size: 70,
            color:
                melonaGreen,
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'به Melona Wallet خوش آمدید',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'یک کیف پول جدید بسازید یا کیف پول قبلی خود را بازیابی کنید.',
            textAlign:
                TextAlign.center,
          ),
          const SizedBox(
            height: 24,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                FilledButton(
              onPressed:
                  create,
              child:
                  const Text(
                'ساخت کیف پول جدید',
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                OutlinedButton(
              onPressed:
                  import,
              child:
                  const Text(
                'بازیابی کیف پول',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
