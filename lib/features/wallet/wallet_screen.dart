import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../models/user.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WalletScreen(),
    );
  }

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final AppUser _user = AppUser.instance;

  int _selectedPackageIndex = 1; // Popular (500 coins, $8.99)
  int _selectedPaymentMethod = 0; // Apple Pay / Google Pay
  bool _subscribeToggle = false;
  String _historyFilter = 'Sent'; // Sent | Received

  final List<_CoinPackage> _packages = const [
    _CoinPackage(
      title: 'Starter Spark',
      price: 1.99,
      coins: 100,
      description: '2 Super Likes + 5 Gifts',
      emoji: '✨',
    ),
    _CoinPackage(
      title: 'Popular',
      price: 8.99,
      coins: 500,
      description: '10 Super Likes + 1 Boost + 25 Gifts',
      emoji: '🔥',
      bonusText: '+10% BONUS',
      badge: 'Most Chosen',
      isPopular: true,
    ),
    _CoinPackage(
      title: 'Dating Pro',
      price: 19.99,
      coins: 1200,
      description: '25 Super Likes + 3 Boosts + 70 Gifts',
      emoji: '🚀',
      savesText: 'Saves \$12',
    ),
    _CoinPackage(
      title: 'Ultimate Lover',
      price: 39.99,
      coins: 3000,
      description: '70 Super Likes + 8 Boosts + 200 Gifts',
      emoji: '👑',
      bonusText: '+35% BONUS',
      savesText: 'Saves \$38',
      badge: 'Best Value',
      isBestValue: true,
    ),
  ];

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _processPayment() {
    final pkg = _packages[_selectedPackageIndex];
    _user.addCoins(pkg.coins);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Successful! Added ${pkg.coins} coins to wallet 🎉'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gold,
      ),
    );

    _close();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPkg = _packages[_selectedPackageIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ThemeColors.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wallet',
                  style: TextStyle(
                    color: ThemeColors.text(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: _close,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ThemeColors.surfaceAlt(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: ThemeColors.text(context),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. BALANCE Card
                  _buildBalanceCard(),
                  const SizedBox(height: 16),

                  // 2. LIMITED TIME OFFER Banner
                  _buildLimitedOfferBanner(),
                  const SizedBox(height: 16),

                  // 3. WHAT IT COSTS Card
                  _buildWhatItCostsCard(),
                  const SizedBox(height: 16),

                  // 4. SUBSCRIBE & SAVE Card
                  _buildSubscribeCard(),
                  const SizedBox(height: 24),

                  // 5. CHOOSE OUTCOME • NOT JUST COINS (Packages)
                  Text(
                    '💎 CHOOSE OUTCOME • NOT JUST COINS',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_packages.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPackageCard(index, _packages[index]),
                    );
                  }),
                  const SizedBox(height: 16),

                  // 6. PAYMENT • ONE-TAP Section
                  Text(
                    '🛡️ PAYMENT • ONE-TAP',
                    style: TextStyle(
                      color: ThemeColors.mutedText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),

                  // 7. Sticky/Floating Payment Button
                  _buildPayButton(selectedPkg),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Secure by Stripe • Coins never expire • No subscription required',
                      style: TextStyle(
                        color: ThemeColors.mutedText(context),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 8. HISTORY Section
                  _buildHistorySection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final coinVal = (_user.walletCoins * 0.0196).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF08A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BALANCE • NEVER EXPIRES',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_user.walletCoins}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '≈ \$$coinVal USD • Coins never expire',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✨ Giftable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Secure • 3D',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitedOfferBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.pink.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: AppColors.pink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡ 50% extra coins',
                  style: TextStyle(
                    color: ThemeColors.text(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ends in 04 : 21 : 34',
                  style: TextStyle(
                    color: ThemeColors.mutedText(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeColors.surfaceAlt(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'LIMITED',
              style: TextStyle(
                color: ThemeColors.text(context),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatItCostsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ThemeColors.border(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WHAT IT\nCOSTS',
            style: TextStyle(
              color: ThemeColors.mutedText(context),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          _buildCostItem('⭐', '25', 'Super Like'),
          _buildCostItem('⚡', '100', 'Boost'),
          _buildCostItem('🎁', '10-200', 'Gifts'),
          _buildCostItem('🔄', '10', 'Rewind'),
        ],
      ),
    );
  }

  Widget _buildCostItem(String emoji, String cost, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF08A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                cost,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscribeCard() {
    final isDark = ThemeColors.isDark(context);
    final cardBg = isDark
        ? const Color(0xFFFDF4FF).withValues(alpha: 0.08)
        : const Color(0xFFFAF5FF);

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: isDark ? 0.25 : 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Subscribe & Save 40%',
                            style: TextStyle(
                              color: ThemeColors.text(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Diva Plus \$9.99/mo • 300 coins/mo',
                        style: TextStyle(
                          color: ThemeColors.mutedText(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _subscribeToggle,
                  activeTrackColor: AppColors.purple,
                  activeThumbColor: Colors.white,
                  onChanged: (val) => setState(() => _subscribeToggle = val),
                ),
              ],
            ),
            if (_subscribeToggle) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.purple,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Diva Plus includes',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '✓ 300 coins/mo',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '✓ Unlimited rewinds',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '✓ See who liked you',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '✓ 3 Boosts/mo',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(int index, _CoinPackage pkg) {
    final isSelected = _selectedPackageIndex == index;
    final isDark = ThemeColors.isDark(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedPackageIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF1E1E26) : Colors.black)
                  : ThemeColors.surface(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? AppColors.pink
                    : ThemeColors.border(context),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.pink.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(pkg.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          pkg.title,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : ThemeColors.text(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (pkg.bonusText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: pkg.isBestValue
                                  ? AppColors.success
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              pkg.bonusText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '\$${pkg.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : ThemeColors.text(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${pkg.coins} coins',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : ThemeColors.text(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (pkg.savesText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white24
                              : ThemeColors.surfaceAlt(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pkg.savesText!,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : ThemeColors.text(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  pkg.description,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white70
                        : ThemeColors.mutedText(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (pkg.badge != null)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: pkg.isBestValue ? const Color(0xFFFEF08A) : AppColors.pink,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                pkg.badge!,
                style: TextStyle(
                  color: pkg.isBestValue ? Colors.black : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      {'name': 'Apple Pay', 'icon': Icons.apple_rounded},
      {'name': 'Google Pay', 'icon': Icons.payment_rounded},
      {'name': 'Card 4242', 'icon': Icons.credit_card_rounded},
    ];

    return Column(
      children: List.generate(methods.length, (index) {
        final item = methods[index];
        final isSelected = _selectedPaymentMethod == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? ThemeColors.text(context)
                  : ThemeColors.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? ThemeColors.text(context)
                    : ThemeColors.border(context),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? ThemeColors.background(context)
                          : ThemeColors.text(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? ThemeColors.background(context)
                            : ThemeColors.text(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? ThemeColors.background(context)
                      : ThemeColors.mutedText(context),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPayButton(_CoinPackage pkg) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.pink, AppColors.purple],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          '🍎 Pay \$${pkg.price.toStringAsFixed(2)} • Get ${pkg.coins} coins ${pkg.bonusText ?? ''}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final historyItems = _historyFilter == 'Sent'
        ? [
            {
              'title': 'Sent 25 to Jelani • Rose 🌹',
              'time': '2 days ago',
              'status': 'DELIVERED',
              'amount': '-25',
              'isPositive': false,
            },
            {
              'title': 'Sent 50 to Amara • Diamond 💎',
              'time': '4 days ago',
              'status': 'DELIVERED',
              'amount': '-50',
              'isPositive': false,
            },
          ]
        : [
            {
              'title': 'Bought 500 coins •',
              'time': '2 days ago',
              'status': '',
              'amount': '+500',
              'isPositive': true,
            },
            {
              'title': 'Received Gift from Maya 🎁',
              'time': '5 days ago',
              'status': '',
              'amount': '+100',
              'isPositive': true,
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📈 HISTORY',
              style: TextStyle(
                color: ThemeColors.mutedText(context),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                _buildFilterPill('Sent', _historyFilter == 'Sent'),
                const SizedBox(width: 6),
                _buildFilterPill('Received', _historyFilter == 'Received'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...historyItems.map((item) {
          final isPos = item['isPositive'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ThemeColors.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ThemeColors.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPos
                            ? AppColors.success.withValues(alpha: 0.15)
                            : ThemeColors.surfaceAlt(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPos
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isPos ? AppColors.success : ThemeColors.text(context),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: ThemeColors.text(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              item['time'] as String,
                              style: TextStyle(
                                color: ThemeColors.mutedText(context),
                                fontSize: 11,
                              ),
                            ),
                            if ((item['status'] as String).isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['status'] as String,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  item['amount'] as String,
                  style: TextStyle(
                    color: isPos ? AppColors.success : AppColors.pink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterPill(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _historyFilter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeColors.text(context)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ThemeColors.text(context)
                : ThemeColors.border(context),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? ThemeColors.background(context)
                : ThemeColors.mutedText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CoinPackage {
  const _CoinPackage({
    required this.title,
    required this.price,
    required this.coins,
    required this.description,
    required this.emoji,
    this.bonusText,
    this.savesText,
    this.badge,
    this.isPopular = false,
    this.isBestValue = false,
  });

  final String title;
  final double price;
  final int coins;
  final String description;
  final String emoji;
  final String? bonusText;
  final String? savesText;
  final String? badge;
  final bool isPopular;
  final bool isBestValue;
}
