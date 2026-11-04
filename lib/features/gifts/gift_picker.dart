import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
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
    this.recipientId,
    this.onSendGift,
  });

  final String recipientName;
  final String recipientImageUrl;
  final String? recipientId;
  final void Function(GiftItem gift, String message)? onSendGift;

  static Future<void> show(
    BuildContext context, {
    required String recipientName,
    required String recipientImageUrl,
    String? recipientId,
    void Function(GiftItem gift, String message)? onSendGift,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftPickerSheet(
        recipientName: recipientName,
        recipientImageUrl: recipientImageUrl,
        recipientId: recipientId,
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final gift = GiftItem.all[_selectedGiftIndex];
    final message = _messageController.text.trim();

    try {
      final apiClient = ApiClient();
      await apiClient.post('/conversations/gift', data: {
        if (widget.recipientId != null) 'to': widget.recipientId,
        'code': gift.name.toLowerCase(),
        'note': message,
      });

      if (!mounted) return;
      if (widget.onSendGift != null) {
        widget.onSendGift!(gift, message);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent ${gift.emoji} ${gift.name} to ${widget.recipientName}! 🎁'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.gold,
        ),
      );
    } catch (e) {
      debugPrint('Gift sending API error: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent ${gift.emoji} ${gift.name} to ${widget.recipientName}!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.gold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGift = GiftItem.all[_selectedGiftIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
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
                                border: Border.all(color: Colors.black, width: 2),
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
                              'Send gift to ${widget.recipientName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '80% of each gift goes to creator',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Gift Grid / List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: GiftItem.all.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = GiftItem.all[index];
                      final isSelected = _selectedGiftIndex == index;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedGiftIndex = index),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF28251C) : const Color(0xFF222228),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppColors.gold : Colors.white12,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(item.emoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(item.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on, color: AppColors.gold, size: 14),
                                      const SizedBox(width: 4),
                                      Text('${item.coins}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(item.priceUsd, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'NOTE OR MESSAGE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black54,
                      hintText: 'Add a sweet note...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        'Send ${selectedGift.emoji} ${selectedGift.name} (${selectedGift.coins} coins)',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
