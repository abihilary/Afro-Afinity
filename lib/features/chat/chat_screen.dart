import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../core/api/api_client.dart';

class ConversationScreen extends ChatScreen {
  const ConversationScreen({super.key, super.onBack, this.name, this.imageUrl});
  final String? name;
  final String? imageUrl;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';

  List<dynamic> _conversations = [];
  List<dynamic> _messages = [];
  bool _isLoadingConversations = true;
  bool _isLoadingMessages = false;
  Map<String, dynamic>? _activeConversation;
  RealtimeChannel? _messageChannel;

  @override
  void initState() {
    super.initState();
    if (widget is ConversationScreen) {
      final convoScreen = widget as ConversationScreen;
      if (convoScreen.name != null) {
        _activeConversation = {
          'other': {'display_name': convoScreen.name, 'avatar_url': convoScreen.imageUrl},
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        };
      }
    }
    _loadConversations();
    _initRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _messageChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initRealtime() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.realtime.setAuth(session.accessToken);
        _messageChannel = Supabase.instance.client
            .channel('public:messages')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              callback: (payload) {
                if (_activeConversation != null) {
                  final newMsg = payload.newRecord;
                  if (newMsg['conversation_id'] == _activeConversation!['id']) {
                    if (mounted) {
                      setState(() {
                        _messages.insert(0, newMsg);
                      });
                    }
                  }
                }
              },
            )
            .subscribe();
      }
    } catch (e) {
      debugPrint('Realtime init error: $e');
    }
  }

  Future<void> _loadConversations() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/conversations');
      debugPrint('Conversations response type: ${res.runtimeType}, data: $res');

      List<dynamic> loaded = [];
      if (res is List) {
        loaded = res;
      } else if (res is Map) {
        if (res['items'] is List) {
          loaded = res['items'];
        } else if (res['conversations'] is List) {
          loaded = res['conversations'];
        } else if (res['data'] is List) {
          loaded = res['data'];
        }
      }

      if (mounted) {
        setState(() {
          _conversations = loaded;
          _isLoadingConversations = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoadingConversations = false;
        });
      }
    }
  }

  Future<void> _openConversation(Map<String, dynamic> convo) async {
    setState(() {
      _activeConversation = convo;
      _isLoadingMessages = true;
      _messages = [];
    });

    final conversationId = convo['id'] ?? convo['conversation_id'];
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/conversations/$conversationId/messages');
      debugPrint('Messages response: $res');

      List<dynamic> fetchedMessages = [];
      if (res is List) {
        fetchedMessages = res;
      } else if (res is Map) {
        if (res['items'] is List) {
          fetchedMessages = res['items'];
        } else if (res['messages'] is List) {
          fetchedMessages = res['messages'];
        } else if (res['data'] is List) {
          fetchedMessages = res['data'];
        }
      }

      if (mounted) {
        setState(() {
          _messages = fetchedMessages;
          _isLoadingMessages = false;
        });
      }
      await apiClient.post('/conversations/$conversationId/read');
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) setState(() => _isLoadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeConversation == null) return;

    _messageController.clear();
    final conversationId = _activeConversation!['id'] ?? _activeConversation!['conversation_id'];

    if (conversationId.toString().startsWith('temp_')) {
      try {
        final apiClient = ApiClient();
        final otherUser = _activeConversation!['other'] ?? _activeConversation!['other_user'];
        final res = await apiClient.post('/conversations/unlock', data: {
          'to': otherUser?['user_id'] ?? otherUser?['id'],
        });
        if (res is Map && (res['conversation_id'] != null || res['id'] != null)) {
          _activeConversation!['id'] = res['conversation_id'] ?? res['id'];
        }
      } catch (e) {
        debugPrint('Unlock conversation error: $e');
      }
    }

    try {
      final apiClient = ApiClient();
      final actualId = _activeConversation!['id'] ?? _activeConversation!['conversation_id'];
      final res = await apiClient.post('/conversations/$actualId/messages', data: {
        'body': text,
      });

      if (res is Map && mounted) {
        setState(() {
          _messages.insert(0, res);
        });
      } else {
        // Fallback local append
        setState(() {
          _messages.insert(0, {
            'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
            'sender_id': Supabase.instance.client.auth.currentUser?.id,
            'body': text,
          });
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
            'sender_id': Supabase.instance.client.auth.currentUser?.id,
            'body': text,
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeConversation != null) {
      return _buildChatThreadView();
    }

    final filteredConversations = _conversations.where((c) {
      final other = c['other'] ?? c['other_user'] ?? {};
      final name = other['display_name'] ?? other['username'] ?? c['name'] ?? 'User';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                ),
              ),
            ),
          Expanded(
            child: _isLoadingConversations
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : filteredConversations.isEmpty
                    ? const Center(
                        child: Text(
                          'No conversations yet.\nStart matching to chat!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredConversations.length,
                        itemBuilder: (context, index) {
                          final convo = filteredConversations[index];
                          final other = convo['other'] ?? convo['other_user'] ?? {};
                          final name = other['display_name'] ?? other['username'] ?? convo['name'] ?? 'User';
                          final age = other['age'] != null ? ', ${other['age']}' : '';
                          final avatar = other['avatar_url'] ?? convo['image_url'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';
                          final lastMessage = convo['last_preview'] ?? convo['last_message']?['body'] ?? convo['message'] ?? 'Say hello 👋';
                          final unread = convo['unread'] ?? convo['unread_count'] ?? 0;
                          final verified = other['verified'] == true;
                          final online = other['online'] == true;

                          return ListTile(
                            onTap: () => _openConversation(convo),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(avatar),
                                ),
                                if (online)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Text('$name$age', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                                if (verified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: AppColors.gold, size: 16),
                                ],
                              ],
                            ),
                            subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            trailing: unread > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                                    child: Text('$unread', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800)),
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatThreadView() {
    final other = _activeConversation!['other'] ?? _activeConversation!['other_user'] ?? {};
    final name = other['display_name'] ?? other['username'] ?? _activeConversation!['name'] ?? 'Chat';
    final avatar = other['avatar_url'] ?? _activeConversation!['image_url'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80';
    final verified = other['verified'] == true;
    final online = other['online'] == true;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => setState(() => _activeConversation = null),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatar)),
                if (online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    if (verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: AppColors.gold, size: 14),
                    ],
                  ],
                ),
                Text(online ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: AppColors.gold),
            onPressed: () {
              // Send gift action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet. Send a greeting!', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] == Supabase.instance.client.auth.currentUser?.id || msg['sender_id'] == null;
                          final body = msg['body'] ?? msg['text'] ?? '';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.gold : Colors.white10,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                body,
                                style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF18181C),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
