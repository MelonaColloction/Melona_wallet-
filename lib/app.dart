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
  final WalletService walletService =
      WalletService();

  final BlockchainService blockchainService =
      BlockchainService();

  List<WalletInfo> wallets = [];

  WalletInfo? selectedWallet;

  ChainConfig selectedChain =
      BlockchainService.ethereumSepolia;

  String balance = '0';

  bool loading = true;
  bool loadingBalance = false;

  @override
  void initState() {
    super.initState();
    loadWallets();
  }

  Future<void> loadWallets() async {
    setState(() {
      loading = true;
    });

    try {
      final result =
          await walletService.getWallets();

      if (!mounted) return;

      setState(() {
        wallets = result;

        if (selectedWallet == null ||
            !result.any(
              (wallet) =>
                  wallet.id ==
                  selectedWallet!.id,
            )) {
          selectedWallet =
              result.isEmpty
                  ? null
                  : result.first;
        }

        loading = false;
      });

      await refreshBalance();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage(
        'خطا در بارگذاری کیف پول',
      );
    }
  }

  Future<void> refreshBalance() async {
    final wallet = selectedWallet;

    if (wallet == null) {
      if (mounted) {
        setState(() {
          balance = '0';
        });
      }
      return;
    }

    setState(() {
      loadingBalance = true;
    });

    try {
      final wei =
          await blockchainService
              .getNativeBalance(
        chain: selectedChain,
        address: wallet.address,
      );

      final formatted =
          blockchainService
              .weiToEther(wei);

      if (!mounted) return;

      setState(() {
        balance = formatted;
        loadingBalance = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        balance = '0';
        loadingBalance = false;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> createWallet() async {
    final nameController =
        TextEditingController();

    bool testnet = true;

    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'ساخت کیف پول جدید',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        nameController,
                    textDirection:
                        TextDirection.rtl,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'نام کیف پول',
                      hintText:
                          'مثلاً کیف پول اصلی',
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  SwitchListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    value: testnet,
                    onChanged:
                        (value) {
                      setDialogState(() {
                        testnet = value;
                      });
                    },
                    title: const Text(
                      'شبکه آزمایشی',
                    ),
                    subtitle: Text(
                      testnet
                          ? 'Testnet - مناسب برای تست'
                          : 'Mainnet - دارایی واقعی',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'انصراف',
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final name =
                        nameController.text
                            .trim();

                    if (name.isEmpty) {
                      return;
                    }

                    try {
                      await walletService
                          .createWallet(
                        name: name,
                        testnet: testnet,
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

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ساخت کیف پول انجام نشد',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'ساخت کیف پول',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (result == true) {
      await loadWallets();

      showMessage(
        'کیف پول با موفقیت ساخته شد',
      );
    }
  }

  Future<void> receive() async {
    final wallet = selectedWallet;

    if (wallet == null) {
      showMessage(
        'ابتدا یک کیف پول انتخاب کنید',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'دریافت',
          ),
          content:
              SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: QrImageView(
                    data: wallet.address,
                    size: 220,
                    backgroundColor:
                        Colors.white,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'این آدرس را برای دریافت دارایی در شبکه انتخاب‌شده استفاده کنید.',
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 14,
                ),
                SelectableText(
                  wallet.address,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: wallet.address,
                  ),
                );

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);

                showMessage(
                  'آدرس کپی شد',
                );
              },
              child: const Text(
                'کپی آدرس',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'بستن',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> send() async {
    showMessage(
      'بخش ارسال در مرحله بعد فعال می‌شود.',
    );
  }

  Future<void> swap() async {
    showMessage(
      'بخش Swap در مرحله اتصال به DEX فعال می‌شود.',
    );
  }

  Future<void> deleteWallet(
    WalletInfo wallet,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'حذف کیف پول',
          ),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید این کیف پول را از دستگاه حذف کنید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'انصراف',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'حذف',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await walletService.deleteWallet(
      wallet.id,
    );

    if (selectedWallet?.id ==
        wallet.id) {
      selectedWallet = null;
    }

    await loadWallets();

    showMessage(
      'کیف پول حذف شد',
    );
  }

  Future<void> selectChain(
    ChainConfig chain,
  ) async {
    setState(() {
      selectedChain = chain;
      balance = '0';
    });

    await refreshBalance();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Directionality(
        textDirection:
            TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child:
                CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Melona Wallet',
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip:
                  'ساخت کیف پول',
              onPressed:
                  createWallet,
              icon: const Icon(
                Icons
                    .add_circle_outline,
              ),
            ),
          ],
        ),
        body:
            RefreshIndicator(
          onRefresh:
              loadWallets,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(
              18,
            ),
            children: [
              if (selectedWallet ==
                  null)
                _EmptyWallet(
                  onCreate:
                      createWallet,
                )
              else ...[
                _WalletCard(
                  wallet:
                      selectedWallet!,
                  balance:
                      balance,
                  chain:
                      selectedChain,
                  loading:
                      loadingBalance,
                ),

                const SizedBox(
                  height: 16,
                ),

                _ChainSelector(
                  selected:
                      selectedChain,
                  onChanged:
                      selectChain,
                ),

                const SizedBox(
                  height: 16,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _ActionButton(
                        icon: Icons
                            .arrow_upward_rounded,
                        title:
                            'ارسال',
                        onTap:
                            send,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                          _ActionButton(
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
                          _ActionButton(
                        icon: Icons
                            .swap_vert_rounded,
                        title:
                            'Swap',
                        onTap:
                            swap,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 28,
                ),

                const Text(
                  'کیف پول‌های من',
                  style: TextStyle(
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
                      _WalletListItem(
                    wallet: wallet,
                    selected:
                        selectedWallet
                                ?.id ==
                            wallet.id,
                    onTap: () async {
                      setState(() {
                        selectedWallet =
                            wallet;
                      });

                      await refreshBalance();
                    },
                    onDelete: () {
                      deleteWallet(
                        wallet,
                      );
                    },
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
  final bool loading;

  const _WalletCard({
    required this.wallet,
    required this.balance,
    required this.chain,
    required this.loading,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topRight,
          end:
              Alignment.bottomLeft,
          colors: [
            Color(0xFF294B30),
            Color(0xFF101710),
          ],
        ),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor:
                    melonaGreen,
                child: Icon(
                  Icons
                      .account_balance_wallet_rounded,
                  color:
                      Colors.black,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  wallet.name,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color: wallet.testnet
                      ? melonaGreen
                          .withValues(
                          alpha: .15,
                        )
                      : Colors.orange
                          .withValues(
                          alpha: .15,
                        ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  wallet.testnet
                      ? 'TESTNET'
                      : 'MAINNET',
                  style:
                      TextStyle(
                    color:
                        wallet.testnet
                            ? melonaGreen
                            : Colors.orange,
                    fontWeight:
                        FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 28,
          ),
          Text(
            chain.name,
            style:
                const TextStyle(
              color:
                  Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Expanded(
                child: loading
                    ? const SizedBox(
                        height: 38,
                        child:
                            Align(
                          alignment:
                              Alignment.centerRight,
                          child:
                              SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        balance,
                        style:
                            const TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
              ),
              Text(
                ' ${chain.symbol}',
                style:
                    const TextStyle(
                  fontSize: 16,
                  color:
                      Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.black.withValues(
                alpha: .2,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    wallet.address,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.white70,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity:
                      VisualDensity
                          .compact,
                  onPressed:
                      () async {
                    await Clipboard
                        .setData(
                      ClipboardData(
                        text:
                            wallet.address,
                      ),
                    );

                    if (!context
                        .mounted) {
                      return;
                    }

                    ScaffoldMessenger
                        .of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content:
                            Text(
                          'آدرس کپی شد',
                        ),
                      ),
                    );
                  },
                  icon:
                      const Icon(
                    Icons.copy_rounded,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainSelector
    extends StatelessWidget {
  final ChainConfig selected;
  final ValueChanged<ChainConfig>
      onChanged;

  const _ChainSelector({
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        child:
            DropdownButtonHideUnderline(
          child:
              DropdownButton<
                  ChainConfig>(
            value: selected,
            isExpanded: true,
            items: chains.map(
              (chain) {
                return DropdownMenuItem<
                    ChainConfig>(
                  value: chain,
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .lan_rounded,
                        size: 20,
                        color:
                            melonaGreen,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        chain.name,
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
            onChanged:
                (chain) {
              if (chain != null) {
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

class _ActionButton
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          const Color(0xFF141A16),
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 18,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    melonaGreen,
                size: 25,
              ),
              const SizedBox(
                height: 7,
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
      ),
    );
  }
}

class _WalletListItem
    extends StatelessWidget {
  final WalletInfo wallet;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WalletListItem({
    required this.wallet,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              selected
                  ? melonaGreen
                  : const Color(
                      0xFF26332A,
                    ),
          child: Icon(
            Icons
                .account_balance_wallet_rounded,
            color: selected
                ? Colors.black
                : Colors.white,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                wallet.name,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              wallet.testnet
                  ? 'TEST'
                  : 'LIVE',
              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w900,
                color: wallet.testnet
                    ? melonaGreen
                    : Colors.orange,
              ),
            ),
          ],
        ),
        subtitle: Text(
          wallet.address,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
        trailing:
            PopupMenuButton<String>(
          onSelected:
              (value) {
            if (value ==
                'delete') {
              onDelete();
            }
          },
          itemBuilder:
              (context) =>
                  const [
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'حذف کیف پول',
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
  final VoidCallback onCreate;

  const _EmptyWallet({
    required this.onCreate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        30,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF141A16),
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
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
            'برای شروع یک کیف پول جدید بسازید.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white60,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                FilledButton.icon(
              onPressed:
                  onCreate,
              icon:
                  const Icon(
                Icons.add_rounded,
              ),
              label:
                  const Text(
                'ساخت کیف پول جدید',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
