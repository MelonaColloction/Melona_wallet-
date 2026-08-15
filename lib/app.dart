import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'wallet_service.dart';

const Color melonaGreen =
    Color(0xFF7BE56B);

class MelonaWalletApp
    extends StatelessWidget {
  const MelonaWalletApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Melona Wallet',

      theme: ThemeData(
        brightness:
            Brightness.dark,
        useMaterial3: true,

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              melonaGreen,
          brightness:
              Brightness.dark,
        ),

        scaffoldBackgroundColor:
            const Color(
          0xFF080C0A,
        ),
      ),

      home:
          const HomePage(),
    );
  }
}

class HomePage
    extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage>
      createState() =>
          _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  final WalletService
      walletService =
      WalletService();

  List<WalletInfo>
      wallets = [];

  WalletInfo? selectedWallet;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadWallets();
  }

  Future<void>
      loadWallets() async {
    final result =
        await walletService
            .getWallets();

    if (!mounted) return;

    setState(() {
      wallets = result;

      selectedWallet =
          result.isEmpty
              ? null
              : result.first;

      loading = false;
    });
  }

  Future<void>
      createWallet() async {
    final nameController =
        TextEditingController();

    bool testnet = true;

    final result =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder:
              (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title:
                  const Text(
                'ساخت کیف پول',
              ),
              content:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        nameController,
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
                    value:
                        testnet,
                    onChanged:
                        (value) {
                      setDialogState(
                        () {
                          testnet =
                              value;
                        },
                      );
                    },
                    title:
                        const Text(
                      'حالت Testnet',
                    ),
                    subtitle:
                        Text(
                      testnet
                          ? 'برای تست'
                          : 'شبکه واقعی',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child:
                      const Text(
                    'انصراف',
                  ),
                ),

                FilledButton(
                  onPressed:
                      () async {
                    final name =
                        nameController
                            .text
                            .trim();

                    if (name.isEmpty) {
                      return;
                    }

                    await walletService
                        .createWallet(
                      name: name,
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

    nameController.dispose();

    if (result == true) {
      await loadWallets();
    }
  }

  Future<void>
      showReceive() async {
    final wallet =
        selectedWallet;

    if (wallet == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (context) {
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
                    wallet.address,
                size: 220,
              ),

              const SizedBox(
                height: 16,
              ),

              SelectableText(
                wallet.address,
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),

          actions: [
            TextButton(
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

  Future<void>
      deleteWallet(
    WalletInfo wallet,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (context) {
        return AlertDialog(
          title:
              const Text(
            'حذف کیف پول',
          ),

          content:
              const Text(
            'آیا مطمئن هستید که می‌خواهید این کیف پول را حذف کنید؟',
          ),

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'انصراف',
              ),
            ),

            FilledButton(
              onPressed:
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },
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
        .deleteWallet(
      wallet.id,
    );

    await loadWallets();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (loading) {
      return const Scaffold(
        body:
            Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Directionality(
      textDirection:
          TextDirection.rtl,

      child:
          Scaffold(
        appBar:
            AppBar(
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
            IconButton(
              onPressed:
                  createWallet,
              icon:
                  const Icon(
                Icons
                    .add_circle_outline,
              ),
              tooltip:
                  'ساخت کیف پول',
            ),
          ],
        ),

        body:
            RefreshIndicator(
          onRefresh:
              loadWallets,

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
                  onCreate:
                      createWallet,
                )
              else ...[
                _WalletCard(
                  wallet:
                      selectedWallet!,
                ),

                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _ActionButton(
                        icon:
                            Icons
                                .arrow_upward_rounded,
                        title:
                            'ارسال',
                        onTap:
                            () {},
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          _ActionButton(
                        icon:
                            Icons
                                .arrow_downward_rounded,
                        title:
                            'دریافت',
                        onTap:
                            showReceive,
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          _ActionButton(
                        icon:
                            Icons
                                .swap_vert_rounded,
                        title:
                            'Swap',
                        onTap:
                            () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 28,
                ),

                const Text(
                  'کیف پول‌های من',
                  style:
                      TextStyle(
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                ...wallets.map(
                  (
                    wallet,
                  ) {
                    return Card(
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
                          maxLines:
                              1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),

                        trailing:
                            PopupMenuButton<
                                String>(
                          onSelected:
                              (
                            value,
                          ) {
                            if (value ==
                                'delete') {
                              deleteWallet(
                                wallet,
                              );
                            }
                          },
                          itemBuilder:
                              (
                            context,
                          ) =>
                              const [
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

                        onTap:
                            () {
                          setState(
                            () {
                              selectedWallet =
                                  wallet;
                            },
                          );
                        },
                      ),
                    );
                  },
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

  const _WalletCard({
    required this.wallet,
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
          colors: [
            Color(
              0xFF243D2A,
            ),
            Color(
              0xFF101710,
            ),
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
                child:
                    Icon(
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
                    fontSize:
                        20,
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
                  color:
                      wallet.testnet
                          ? melonaGreen
                          : Colors.orange,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 28,
          ),

          const Text(
            'آدرس کیف پول',
            style:
                TextStyle(
              color:
                  Colors.white60,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          SelectableText(
            wallet.address,
            style:
                const TextStyle(
              fontSize:
                  13,
            ),
          ),
        ],
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
    return InkWell(
      onTap:
          onTap,

      borderRadius:
          BorderRadius.circular(
        18,
      ),

      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 18,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFF141A16,
          ),

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
        28,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF141A16,
        ),

        borderRadius:
            BorderRadius.circular(
          28,
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons
                .account_balance_wallet_rounded,
            size:
                70,
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
              fontSize:
                  23,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width:
                double.infinity,

            child:
                FilledButton(
              onPressed:
                  onCreate,
              child:
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
