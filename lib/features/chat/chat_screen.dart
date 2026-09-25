import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../core/widgets/safe_image.dart';
import '../gifts/gift_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';

  final _newMatches = const <_NewMatch>[
    _CoinMatch(
      name: 'Amara',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80&auto=format&fit=crop',
      isOnline: true,
    ),
    _CoinMatch(
      name: 'Jelani',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80&auto=format&fit=crop',
      isOnline: true,
    ),
    _CoinMatch(
      name: 'Zanele',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80&auto=format&fit=crop',
      isOnline: true,
    ),
    _CoinMatch(
      name: 'Nia',
      imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80&auto=format&fit=crop',
      isOnline: true,
    ),
  ];

  final _conversations = const <_Conversation>[
    _Conversation(
      name: 'Amara',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80&auto=format&fit=crop',
      message: 'That Ankara market in Yaba - sti...',
      time: '2m',
      unreadCount: 2,
      isOnline: true,
    ),
    _Conversation(
      name: 'Jelani',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80&auto=format&fit=crop',
      message: 'You: Haha Waakye supremacy co...',
      time: '1h',
      unreadCount: 0,
      isOnline: true,
      hasDeliveredCheck: true,
    ),
    _Conversation(
      name: 'Zanele',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80&auto=format&fit=crop',
      message: 'Amapiano night in CBD tomorrow...',
      time: '3h',
      unreadCount: 0,
      isOnline: true,
      hasDeliveredCheck: true,
    ),
    _Conversation(
      name: 'Nia Laurent',
      imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80&auto=format&fit=crop',
      message: 'Found this kente pop-up you mig...',
      time: '5h',
      unreadCount: 0,
      isOnline: true,
      hasDeliveredCheck: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredConversations = _conversations
        .where(
          (conversation) => conversation.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.background(context),
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: ThemeColors.text(context),
                  size: 20,
                ),
              )
            : null,
        title: Text(
          'Messages',
          style: TextStyle(
            color: ThemeColors.text(context),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
              icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            _ConversationSearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // NEW MATCHES Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NEW MATCHES',
                        style: TextStyle(
                          color: ThemeColors.mutedText(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${_newMatches.length}',
                        style: TextStyle(
                          color: ThemeColors.mutedText(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Matches Scroll Row
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _newMatches.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final match = _newMatches[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ConversationScreen(
                                name: match.name,
                                imageUrl: match.imageUrl,
                                isOnline: match.isOnline,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 62,
                                  height: 62,
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.pink,
                                        AppColors.purple,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: SafeImage(
                                      urlOrPath: match.imageUrl,
                                      width: 57,
                                      height: 57,
                                    ),
                                  ),
                                ),
                                if (match.isOnline)
                                  Positioned(
                                    bottom: 1,
                                    right: 1,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.black,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              match.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: .06),
                ),
                const SizedBox(height: 8),

                // Conversations List
                if (filteredConversations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No conversations found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ...filteredConversations.map((conversation) {
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationScreen(
                            name: conversation.name,
                            imageUrl: conversation.imageUrl,
                            isOnline: conversation.isOnline,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationSearchBar extends StatelessWidget {
  const _ConversationSearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.gold,
              size: 22,
            ),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 19,
                    ),
                  ),
            hintText: 'Search messages',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final _Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: SafeImage(
                    urlOrPath: conversation.imageUrl,
                    width: 52,
                    height: 52,
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.black, width: 2),
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
                    conversation.name,
                    style: TextStyle(
                      color: ThemeColors.text(context),
                      fontSize: 15,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: conversation.unreadCount > 0
                          ? ThemeColors.text(context)
                          : ThemeColors.mutedText(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                if (conversation.unreadCount > 0)
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (conversation.hasDeliveredCheck == true)
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    this.isOnline = true,
  });

  final String name;
  final String imageUrl;
  final bool isOnline;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _messages = <_Message>[
    const _Message(
      text: "haha don't start! Both kings, but Tems for me",
      isMine: true,
      time: 'Yesterday 9:44 PM',
    ),
    const _Message(
      text: 'Fr! Her Tiny Desk was spiritual',
      isMine: false,
      time: 'Yesterday 9:45 PM',
    ),
    const _Message(
      text: 'Amara sent you 50 coins',
      isMine: false,
      giftTitle: 'Amara gifted you Cocktail',
      giftSubtitle: '50 coins • Drinks on me',
      giftCoins: 50,
      time: 'Yesterday 9:46 PM',
    ),
    const _Message(
      text: 'For the Jollof debate prep 😂',
      isMine: false,
      time: 'Yesterday 9:46 PM',
    ),
    const _Message(
      text: 'You too kind! I owe you a Waakye guide',
      isMine: true,
      time: 'Today 10:12 AM',
    ),
    const _Message(
      text: 'That Ankara market in Yaba - still open?',
      isMine: false,
      time: 'Today 10:15 AM',
    ),
  ];

  bool _isRecording = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendText([String? text]) {
    final content = (text ?? _messageController.text).trim();
    if (content.isEmpty) return;

    setState(() => _messages.add(_Message(text: content, isMine: true)));
    _messageController.clear();
    _scrollToLatest();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 75,
    );
    if (image == null) return;

    final imageBytes = await image.readAsBytes();
    if (!mounted) return;

    setState(
      () => _messages.add(
        _Message(text: 'Photo', isMine: true, imageBytes: imageBytes),
      ),
    );
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleVoiceMessage() {
    if (_isRecording) {
      setState(() => _isRecording = false);
      _sendText('🎤 Voice message');
      return;
    }
    setState(() => _isRecording = true);
  }

  Future<void> _openGiftPicker() async {
    await GiftPickerSheet.show(
      context,
      recipientName: widget.name,
      recipientImageUrl: widget.imageUrl,
      onSendGift: (gift, note) {
        setState(() {
          _messages.add(
            _Message(
              text: note.isNotEmpty ? note : 'Sent a ${gift.name} gift',
              isMine: true,
              giftTitle: 'You gifted ${widget.name} ${gift.name}',
              giftSubtitle: '${gift.coins} coins • ${gift.subtitle}',
              giftCoins: gift.coins,
              time: 'Just now',
            ),
          );
        });
        _scrollToLatest();
      },
    );
  }

  void _openAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _AttachmentSheet(
        onGallery: () {
          Navigator.pop(sheetContext);
          _pickImage(ImageSource.gallery);
        },
        onCamera: () {
          Navigator.pop(sheetContext);
          _pickImage(ImageSource.camera);
        },
        onLocation: () {
          Navigator.pop(sheetContext);
          _sendText('📍 Location shared');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.background(context),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ThemeColors.text(context),
            size: 19,
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: SafeImage(
                urlOrPath: widget.imageUrl,
                width: 38,
                height: 38,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    color: ThemeColors.text(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.isOnline ? 'Online now' : 'Recently active',
                  style: TextStyle(
                    color: ThemeColors.mutedText(context),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openGiftPicker,
            tooltip: 'Send a gift',
            icon: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.gold,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              itemCount: _messages.length,
              itemBuilder: (_, index) => _MessageBubble(
                message: _messages[index],
              ),
            ),
          ),
          if (!_isRecording)
            _SuggestionRow(onSuggestionSelected: _sendText),
          SafeArea(
            top: false,
            child: _MessageComposer(
              controller: _messageController,
              isRecording: _isRecording,
              onAttach: _openAttachmentSheet,
              onGift: _openGiftPicker,
              onSend: _sendText,
              onVoiceTap: _toggleVoiceMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.onSuggestionSelected});

  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'How is your day?',
      'Want to meet up?',
      'That sounds great!',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
            backgroundColor: AppColors.darkSurface2,
            side: BorderSide(color: Colors.white.withValues(alpha: .09)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onPressed: () => onSuggestionSelected(suggestion),
          );
        },
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isRecording,
    required this.onAttach,
    required this.onGift,
    required this.onSend,
    required this.onVoiceTap,
  });

  final TextEditingController controller;
  final bool isRecording;
  final VoidCallback onAttach;
  final VoidCallback onGift;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Row(
        children: [
          _ComposerIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Attach',
            onTap: onAttach,
          ),
          _ComposerIconButton(
            icon: Icons.card_giftcard_rounded,
            tooltip: 'Send gift',
            color: AppColors.gold,
            onTap: onGift,
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.darkSurface2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isRecording
                      ? AppColors.pink
                      : Colors.white.withValues(alpha: .07),
                ),
              ),
              child: isRecording
                  ? const Center(
                      child: Text(
                        'Recording… tap stop to send',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          _ComposerIconButton(
            icon: isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
            tooltip: isRecording ? 'Send voice message' : 'Record voice message',
            color: isRecording ? AppColors.pink : Colors.white70,
            filled: isRecording,
            onTap: onVoiceTap,
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.trim().isEmpty || isRecording) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _ComposerIconButton(
                  icon: Icons.send_rounded,
                  tooltip: 'Send',
                  color: Colors.black,
                  filled: true,
                  fillColor: AppColors.gold,
                  onTap: onSend,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = Colors.white70,
    this.filled = false,
    this.fillColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  final bool filled;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? (fillColor ?? color) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: filled && fillColor == null ? Colors.white : color,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    // If message is a Gift Card (matching Image 5)
    if (message.giftTitle != null) {
      return Align(
        alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF08A),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🍸', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.giftTitle!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.giftSubtitle ?? '',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '"${message.text}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Thank you',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '+25 coins to you',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (message.time != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    message.time!,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: message.imageBytes == null
            ? const EdgeInsets.symmetric(horizontal: 15, vertical: 11)
            : const EdgeInsets.all(4),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: message.isMine ? AppColors.gold : AppColors.darkSurface2,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            message.imageBytes == null
                ? Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMine ? Colors.black : Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      message.imageBytes!,
                      width: 220,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
            if (message.time != null) ...[
              const SizedBox(height: 2),
              Text(
                message.time!,
                style: TextStyle(
                  color: message.isMine ? Colors.black45 : Colors.white38,
                  fontSize: 9.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({
    required this.onGallery,
    required this.onCamera,
    required this.onLocation,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share something',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: spaceAround,
              children: [
                _AttachmentOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF8068E8),
                  onTap: onGallery,
                ),
                _AttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: AppColors.terracotta,
                  onTap: onCamera,
                ),
                _AttachmentOption(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  color: AppColors.success,
                  onTap: onLocation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const MainAxisAlignment spaceAround = MainAxisAlignment.spaceAround;
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class _NewMatch {
  String get name;
  String get imageUrl;
  bool get isOnline;
}

class _CoinMatch implements _NewMatch {
  const _CoinMatch({
    required this.name,
    required this.imageUrl,
    required this.isOnline,
  });

  @override
  final String name;
  @override
  final String imageUrl;
  @override
  final bool isOnline;
}

class _Conversation {
  const _Conversation({
    required this.name,
    required this.imageUrl,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    this.hasDeliveredCheck = false,
  });

  final String name;
  final String imageUrl;
  final String message;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool hasDeliveredCheck;
}

class _Message {
  const _Message({
    required this.text,
    required this.isMine,
    this.imageBytes,
    this.giftTitle,
    this.giftSubtitle,
    this.giftCoins,
    this.time,
  });

  final String text;
  final bool isMine;
  final Uint8List? imageBytes;
  final String? giftTitle;
  final String? giftSubtitle;
  final int? giftCoins;
  final String? time;
}
