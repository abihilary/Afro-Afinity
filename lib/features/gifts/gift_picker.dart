import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../core/widgets/safe_image.dart';

class GiftItem {
  const GiftItem({
    required this.name,
    required this.emoji,
    required this.coins,
    required this.subtitle,
    required this.priceUsd,
    required this.cardBgColor,
  });

  final String name;
  final String emoji;
  final int coins;
  final String subtitle;
  final String priceUsd;
  final Color cardBgColor;

  static const List<GiftItem> all = [
    GiftItem(
      name: 'Rose',
      emoji: '🌹',
      coins: 10,
      subtitle: 'Sweet hello',
      priceUsd: '\$0.20',
      cardBgColor: Color(0xFF18181F),
    ),
    GiftItem(
      name: 'Heart',
      emoji: '💖',
      coins: 25,
      subtitle: 'You like them',
      priceUsd: '\$0.50',
      cardBgColor: Color(0xFFFDF2F8),
    ),
    GiftItem(
      name: 'Cocktail',
      emoji: '🍸',
      coins: 50,
      subtitle: 'Drinks on me',
      priceUsd: '\$0.99',
      cardBgColor: Color(0xFFFEF9C3),
    ),
    GiftItem(
      name: 'Diamond',
      emoji: '💎',
      coins: 100,
      subtitle: 'You shine',
      priceUsd: '\$1.99',
      cardBgColor: Color(0xFFEFF6FF),
    ),
    GiftItem(
      name: 'Crown',
      emoji: '👑',
      coins: 200,
      subtitle: 'Ultimate flex',
      priceUsd: '\$3.99',
      cardBgColor: Color(0xFFFEF08A),
    ),
  ];
}

class GiftPickerSheet extends StatefulWidget {
  const GiftPickerSheet({
    super.key,
    required this.recipientName,
    required this.recipientImageUrl,
    this.onSendGift,
  });

  final String recipientName;
  final String recipientImageUrl;
  final void Function(GiftItem gift, String message)? onSendGift;

  static Future<void> show(
    BuildContext context, {
    required String recipientName,
    required String recipientImageUrl,
    void Function(GiftItem gift, String message)? onSendGift,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftPickerSheet(
        recipientName: recipientName,
        recipientImageUrl: recipientImageUrl,
        onSendGift: onSendGift,
      ),
    );
  }

  @override
  State<GiftPickerSheet> createState() => _GiftPickerSheetState();
}

class _GiftPickerSheetState extends State<GiftPickerSheet> {
  int _selectedGiftIndex = 0;
  final _messageController =
      TextEditingController(text: 'You caught my eye 😊');

  final List<String> _suggestions = const [
    'You caught my eye 😊',
    'Love your prompt!',
    'Drinks on me 🍸',
    'Great smile! ✨',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    final gift = GiftItem.all[_selectedGiftIndex];
    final message = _messageController.text.trim();

    if (widget.onSendGift != null) {
      widget.onSendGift!(gift, message);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent ${gift.emoji} ${gift.name} to ${widget.recipientName}!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGift = GiftItem.all[_selectedGiftIndex];
    final currentMessage = _messageController.text;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header Bar Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row with Avatar
                  Row(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SafeImage(
                              urlOrPath: widget.recipientImageUrl,
                              width: 52,
                              height: 52,
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF08A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Center(
                                child: Text('🌹', style: TextStyle(fontSize: 10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Make ${widget.recipientName} smile',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.trending_up_rounded,
                                        color: AppColors.purple,
                                        size: 13,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        '3x match rate',
                                        style: TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Gifts & Appreciation',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gift Selection Header
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CHOOSE GIFT • ANTI-SPAM 3/DAY',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        '1/3 sent today',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontally Scrollable Gift List
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: GiftItem.all.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final gift = GiftItem.all[index];
                        final isSelected = _selectedGiftIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedGiftIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 110,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF141419)
                                  : gift.cardBgColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.black.withValues(alpha: 0.08),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(gift.emoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 6),
                                Text(
                                  gift.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  gift.subtitle,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.monetization_on_outlined,
                                        color: AppColors.gold,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${gift.coins}',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ADD MESSAGE Section
                  const Text(
                    'ADD MESSAGE',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Suggestion Pills
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        final isSelected =
                            _messageController.text == suggestion;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _messageController.text = suggestion;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message Input Field
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextField(
                          controller: _messageController,
                          maxLength: 60,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13.5,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Add a friendly note...',
                            counterText: '',
                          ),
                        ),
                        Text(
                          '${currentMessage.length}/60',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // PREVIEW Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.black54,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'PREVIEW',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            text: '${widget.recipientName} will see: ',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '"Kofi gifted you a ${selectedGift.name} ${selectedGift.emoji}${currentMessage.isNotEmpty ? ' - $currentMessage' : ''}"',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.success,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '50% to ${widget.recipientName} • 50% platform • delivered instantly',
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        colors: [AppColors.pink, AppColors.purple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.pink.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        '${selectedGift.emoji} Send ${selectedGift.name} • ${selectedGift.coins} 🪙 • ${selectedGift.priceUsd}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Balance: 1,240 coins • Gift increases match rate 3x 🚀',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
