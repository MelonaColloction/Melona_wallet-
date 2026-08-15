import 'package:flutter/material.dart';

class MelonaWalletApp extends StatefulWidget {
  const MelonaWalletApp({super.key});

  @override
  State<MelonaWalletApp> createState() => _MelonaWalletAppState();
}

class _MelonaWalletAppState extends State<MelonaWalletApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _changeLanguage(String language) {
    setState(() => _language = language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Melona Wallet',
      themeMode: _themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: HomePage(
        language: _language,
        themeMode: _themeMode,
        onThemeChanged: _toggleTheme,
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}

const Color melonaGreen = Color(0xFF75D66A);
const Color darkBackground = Color(0xFF0B0F0D);
const Color darkCard = Color(0xFF141A17);

ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: darkBackground,
  colorScheme: ColorScheme.fromSeed(
    seedColor: melonaGreen,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  cardTheme: const CardThemeData(
    color: darkCard,
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  ),
);

ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: melonaGreen,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  cardTheme: const CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
);

class HomePage extends StatelessWidget {
  final String language;
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const HomePage({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  String t(String key) {
    const translations = {
      'en': {
        'hello': 'Welcome to Melona',
        'balance': 'Total Balance',
        'assets': 'Your Assets',
        'send': 'Send',
        'receive': 'Receive',
        'swap': 'Swap',
        'wallet': 'Wallet',
        'nft': 'NFT',
        'settings': 'Settings',
        'bitcoin': 'Bitcoin',
        'ethereum': 'Ethereum',
        'usdt': 'Tether USD',
        'coming': 'Coming Soon',
      },
      'fa': {
        'hello': 'به ملونا خوش آمدید',
        'balance': 'موجودی کل',
        'assets': 'دارایی‌های شما',
        'send': 'ارسال',
        'receive': 'دریافت',
        'swap': 'سواپ',
        'wallet': 'کیف پول',
        'nft': 'NFT',
        'settings': 'تنظیمات',
        'bitcoin': 'بیت‌کوین',
        'ethereum': 'اتریوم',
        'usdt': 'تتر',
        'coming': 'به‌زودی',
      },
      'fr': {
        'hello': 'Bienvenue sur Melona',
        'balance': 'Solde total',
        'assets': 'Vos actifs',
        'send': 'Envoyer',
        'receive': 'Recevoir',
        'swap': 'Swap',
        'wallet': 'Portefeuille',
        'nft': 'NFT',
        'settings': 'Paramètres',
        'bitcoin': 'Bitcoin',
        'ethereum': 'Ethereum',
        'usdt': 'Tether USD',
        'coming': 'Bientôt',
      },
      'de': {
        'hello': 'Willkommen bei Melona',
        'balance': 'Gesamtguthaben',
        'assets': 'Ihre Vermögenswerte',
        'send': 'Senden',
        'receive': 'Empfangen',
        'swap': 'Swap',
        'wallet': 'Wallet',
        'nft': 'NFT',
        'settings': 'Einstellungen',
        'bitcoin': 'Bitcoin',
        'ethereum': 'Ethereum',
        'usdt': 'Tether USD',
        'coming': 'Demnächst',
      },
      'zh': {
        'hello': '欢迎使用 Melona',
        'balance': '总余额',
        'assets': '您的资产',
        'send': '发送',
        'receive': '接收',
        'swap': '兑换',
        'wallet': '钱包',
        'nft': 'NFT',
        'settings': '设置',
        'bitcoin': '比特币',
        'ethereum': '以太坊',
        'usdt': '泰达币',
        'coming': '即将推出',
      },
    };

    return translations[language]?[key] ??
        translations['en']![key] ??
        key;
  }

  bool get isRtl => language == 'fa';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: melonaGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t('hello'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: onThemeChanged,
                        icon: Icon(
                          themeMode == ThemeMode.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: _BalanceCard(t: t),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.arrow_upward_rounded,
                          label: t('send'),
                          onTap: () => _showComingSoon(context, t),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.arrow_downward_rounded,
                          label: t('receive'),
                          onTap: () => _showComingSoon(context, t),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.swap_vert_rounded,
                          label: t('swap'),
                          onTap: () => _showComingSoon(context, t),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    t('assets'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _AssetTile(
                      icon: Icons.currency_bitcoin_rounded,
                      name: t('bitcoin'),
                      symbol: 'BTC',
                      amount: '0.000000',
                      value: '\$0.00',
                      change: '+0.00%',
                    ),
                    const SizedBox(height: 10),
                    _AssetTile(
                      icon: Icons.currency_exchange_rounded,
                      name: t('ethereum'),
                      symbol: 'ETH',
                      amount: '0.000000',
                      value: '\$0.00',
                      change: '+0.00%',
                    ),
                    const SizedBox(height: 10),
                    _AssetTile(
                      icon: Icons.monetization_on_rounded,
                      name: t('usdt'),
                      symbol: 'USDT',
                      amount: '0.00',
                      value: '\$0.00',
                      change: '0.00%',
                    ),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverToBoxAdapter(
                  child: _LanguageSelector(
                    current: language,
                    onChanged: onLanguageChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: t('wallet'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.image_rounded),
              label: t('nft'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_rounded),
              label: t('settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String Function(String) text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text('coming')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String Function(String) t;

  const _BalanceCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2B23),
            Color(0xFF111713),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('balance'),
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$0.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: melonaGreen,
              ),
              SizedBox(width: 5),
              Text(
                '0.00%',
                style: TextStyle(
                  color: melonaGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: melonaGreen),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String symbol;
  final String amount;
  final String value;
  final String change;

  const _AssetTile({
    required this.icon,
    required this.name,
    required this.symbol,
    required this.amount,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: melonaGreen.withValues(alpha: 0.12),
            child: Icon(icon, color: melonaGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '$amount $symbol',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                change,
                style: const TextStyle(
                  color: melonaGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _LanguageSelector({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: current,
      decoration: const InputDecoration(
        labelText: 'Language',
        prefixIcon: Icon(Icons.language_rounded),
      ),
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'fa',
          child: Text('فارسی'),
        ),
        DropdownMenuItem(
          value: 'fr',
          child: Text('Français'),
        ),
        DropdownMenuItem(
          value: 'de',
          child: Text('Deutsch'),
        ),
        DropdownMenuItem(
          value: 'zh',
          child: Text('简体中文'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
