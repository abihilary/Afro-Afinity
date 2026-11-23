import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../../core/api/api_client.dart';
import '../../core/services/storage_service.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/ui/api_errors.dart';
import '../../core/util/json.dart';
import '../../core/util/time.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/safe_image.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../discover/member_actions.dart';
import '../gifts/gift_picker.dart';
import 'chat_providers.dart';

/// One thread. History pages with `before`; new messages arrive over a
/// Supabase channel filtered to this conversation (the socket carries the
/// member's JWT, set by `sessionProvider`). The sender's own insert comes back
/// over the socket too, so every append is de-duplicated by id.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ThreadHeader? _header;
  Object? _error;
  final List<Message> _msgs = []; // newest last
  String? _nextBefore;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _typing = false;
  Timer? _typingTimer;
  DateTime _lastTyped = DateTime(2000);
  RealtimeChannel? _channel;

  String get _id => widget.conversationId;
  String get _myId => ref.read(userIdProvider) ?? '';
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // The list is reversed: older history is at the max extent.
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _loadOlder();
    });
    _load();
    _subscribe();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_channel != null) supabase.removeChannel(_channel!);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getJson('/conversations/$_id'),
        _api.getJson('/conversations/$_id/messages'),
      ]);
      if (!mounted) return;
      setState(() {
        _header = ThreadHeader(results[0]);
        _msgs
          ..clear()
          ..addAll(asMapList(results[1]['items']).map((j) => Message.fromJson(j, myId: _myId)));
        _nextBefore = asString(results[1]['next_before']);
        _error = null;
      });
      _markRead();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Re-reads the newest page and merges it in: used when a message arrives
  /// over the socket, because the socket row has no signed attachment URL and
  /// no gift details.
  Future<void> _refreshLatest() async {
    try {
      final j = await _api.getJson('/conversations/$_id/messages');
      if (!mounted) return;
      _merge(asMapList(j['items']).map((m) => Message.fromJson(m, myId: _myId)));
    } catch (_) {}
  }

  void _merge(Iterable<Message> incoming) {
    final byId = {for (final m in _msgs) m.id: m};
    for (final m in incoming) {
      byId[m.id] = m;
    }
    final list = byId.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    setState(() => _msgs
      ..clear()
      ..addAll(list));
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || _nextBefore == null) return;
    setState(() => _loadingOlder = true);
    try {
      final j = await _api.getJson('/conversations/$_id/messages', query: {'before': _nextBefore});
      if (!mounted) return;
      _merge(asMapList(j['items']).map((m) => Message.fromJson(m, myId: _myId)));
      setState(() => _nextBefore = asString(j['next_before']));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  void _subscribe() {
    _channel = supabase
        .channel('conv:$_id')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: _id),
          callback: (payload) {
            final row = payload.newRecord;
            if (asString(row['sender_id']) == _myId) return; // our own echo; the POST already added it
            setState(() => _typing = false);
            _refreshLatest();
            _markRead();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: _id),
          callback: (payload) {
            final id = asString(payload.newRecord['id']);
            final readAt = asDate(payload.newRecord['read_at']);
            if (id == null) return;
            setState(() {
              for (var i = 0; i < _msgs.length; i++) {
                if (_msgs[i].id == id) {
                  final m = _msgs[i];
                  _msgs[i] = Message(
                    id: m.id, senderId: m.senderId, body: m.body, attachmentPath: m.attachmentPath,
                    attachmentUrl: m.attachmentUrl, gift: m.gift, createdAt: m.createdAt, readAt: readAt, mine: m.mine,
                  );
                }
              }
            });
          },
        )
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (asString(payload['user']) == _myId || !mounted) return;
            setState(() => _typing = true);
            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(milliseconds: 2500), () {
              if (mounted) setState(() => _typing = false);
            });
          },
        )
        .subscribe();
  }

  void _markRead() {
    _api.post('/conversations/$_id/read').then((_) => ref.invalidate(conversationsProvider)).catchError((_) {});
  }

  void _onTyped(String _) {
    final now = DateTime.now();
    if (now.difference(_lastTyped).inMilliseconds > 1500) {
      _lastTyped = now;
      _channel?.sendBroadcastMessage(event: 'typing', payload: {'user': _myId});
    }
    setState(() {});
  }

  Future<void> _send({String? attachmentPath}) async {
    final body = _input.text.trim();
    if (body.isEmpty && attachmentPath == null) return;
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final temp = Message(id: tempId, senderId: _myId, body: body.isEmpty ? null : body, attachmentPath: attachmentPath, createdAt: DateTime.now(), mine: true, pending: true);
    setState(() {
      _msgs.add(temp);
      if (attachmentPath == null) _input.clear();
      _sending = true;
    });
    try {
      final j = await _api.post('/conversations/$_id/messages', data: {
        if (temp.body != null) 'body': temp.body,
        'attachment_path': ?attachmentPath,
      });
      final sent = Message.fromJson(asMap(j), myId: _myId);
      setState(() => _msgs.removeWhere((m) => m.id == tempId));
      _merge([sent]);
      if (attachmentPath != null) _refreshLatest(); // for the signed URL
      if (_header?.messagesLeft != null) _reloadHeader();
    } catch (e) {
      setState(() {
        final i = _msgs.indexWhere((m) => m.id == tempId);
        if (i >= 0) _msgs[i] = temp.copyWith(pending: false, failed: true);
      });
      if (!mounted) return;
      if (e is ApiException && e.code == 'message_quota_reached') {
        _reloadHeader();
      } else {
        handleApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reloadHeader() async {
    try {
      final h = ThreadHeader(await _api.getJson('/conversations/$_id'));
      if (mounted) setState(() => _header = h);
    } catch (_) {}
  }

  void _retry(Message m) {
    setState(() => _msgs.removeWhere((x) => x.id == m.id));
    _input.text = m.body ?? '';
    _send(attachmentPath: m.attachmentPath);
  }

  Future<void> _attach() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    try {
      final path = await ref.read(storageServiceProvider).upload(bucket: 'chat-attachments', bytes: await x.readAsBytes(), ext: extOf(x.name), filename: x.name);
      await _send(attachmentPath: path);
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  Future<void> _continue() async {
    try {
      final r = await _api.postJson('/conversations/$_id/continue');
      final balance = asInt(r['balance']);
      if (balance != null) ref.read(meProvider.notifier).setBalance(balance);
      _reloadHeader();
    } catch (e) {
      if (mounted) handleApiError(context, e);
    }
  }

  Future<void> _gift() async {
    final h = _header;
    if (h == null) return;
    final conv = await GiftSheet.show(context, ref, toUserId: h.other.userId, toName: h.other.name);
    if (conv != null) _refreshLatest();
  }

  void _menu() {
    final h = _header;
    if (h == null) return;
    final actions = MemberActions(context, ref);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (h.other.username != null && !h.otherGone)
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppColors.gold),
              title: const Text('View profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/u/${h.other.username}');
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.error),
            title: const Text('Report', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              actions.report(h.other.userId, h.other.name).then((sent) => sent ? _reloadHeader() : null);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: AppColors.error),
            title: const Text('Block', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              actions.block(h.other.userId, h.other.name).then((ok) => ok ? _reloadHeader() : null);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = _header;
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: h == null
            ? null
            : InkWell(
                onTap: h.other.username == null || h.otherGone ? null : () => context.push('/u/${h.other.username}'),
                child: Row(children: [
                  Avatar(url: h.otherGone ? null : h.other.avatarUrl, size: 38, online: h.other.online),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h.otherGone ? 'Former member' : h.other.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(_typing ? 'typing…' : h.other.online ? 'Online' : (h.other.city ?? ''),
                          style: TextStyle(fontSize: 12, color: _typing || h.other.online ? AppColors.success : Colors.white54)),
                    ]),
                  ),
                ]),
              ),
        actions: [
          if (h != null && !h.blocked && !h.otherGone)
            IconButton(tooltip: 'Send a gift', onPressed: _gift, icon: const Icon(Icons.card_giftcard_rounded, color: AppColors.gold)),
          IconButton(onPressed: _menu, icon: const Icon(Icons.more_vert_rounded)),
        ],
      ),
      body: _error != null && h == null
          ? ErrorView(error: _error!, onRetry: _load)
          : h == null
              ? const LoadingView()
              : Column(children: [
                  Expanded(
                    child: _msgs.isEmpty
                        ? EmptyState(
                            icon: Icons.waving_hand_outlined,
                            title: 'Say hello to ${h.other.name}',
                            body: h.openedVia == 'match' ? 'You matched — the first message is the hardest. Ask about their prompts.' : null,
                          )
                        : ListView.builder(
                            controller: _scroll,
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            itemCount: _msgs.length + (_nextBefore != null ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _msgs.length) return const Padding(padding: EdgeInsets.all(12), child: LoadingView());
                              final idx = _msgs.length - 1 - i;
                              final m = _msgs[idx];
                              final prev = idx > 0 ? _msgs[idx - 1] : null;
                              final showDay = prev == null || dayLabel(prev.createdAt) != dayLabel(m.createdAt);
                              final isLastMine = m.mine && _msgs.sublist(idx + 1).every((x) => !x.mine);
                              return Column(children: [
                                if (showDay)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text(dayLabel(m.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  ),
                                _Bubble(message: m, showRead: isLastMine, onRetry: () => _retry(m)),
                              ]);
                            },
                          ),
                  ),
                  _footer(h),
                ]),
    );
  }

  Widget _footer(ThreadHeader h) {
    if (h.blocked || h.otherGone) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(h.otherGone ? 'This member has left Afro Affinity.' : 'This conversation is closed.',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
        ),
      );
    }
    if (h.messagesLeft == 0) {
      final store = ref.watch(storeProvider).valueOrNull;
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.darkSurface,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('You have used your free messages here. Keep the conversation going, or wait for a reply.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.4)),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Keep chatting${store == null ? '' : ' · ${store.unlockCoins} coins'}', onPressed: _continue, height: 48),
          ]),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(color: AppColors.darkSurface, border: Border(top: BorderSide(color: Colors.white10))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (h.messagesLeft != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${h.messagesLeft} free message${h.messagesLeft == 1 ? '' : 's'} left until they reply',
                  style: const TextStyle(color: AppColors.gold, fontSize: 12)),
            ),
          Row(children: [
            IconButton(onPressed: _sending ? null : _attach, icon: const Icon(Icons.image_outlined, color: Colors.white60)),
            Expanded(
              child: TextField(
                controller: _input,
                onChanged: _onTyped,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Message…',
                  hintStyle: const TextStyle(color: Colors.white30),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  fillColor: AppColors.darkSurface2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black, disabledBackgroundColor: Colors.white12),
              onPressed: _input.text.trim().isEmpty ? null : () => _send(),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.showRead, required this.onRetry});
  final Message message;
  final bool showRead;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final mine = m.mine;
    final store = ref.watch(storeProvider).valueOrNull;
    final gift = m.gift == null ? null : store?.gift(m.gift!.code);
    Widget content;
    if (m.gift != null && m.body == null && m.attachmentPath == null) {
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        Text(gift?.emoji ?? '🎁', style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 4),
        Text(mine ? 'You sent ${gift?.labelEn ?? 'a gift'}' : 'Sent you ${gift?.labelEn ?? 'a gift'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ]);
    } else {
      content = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (m.gift != null) Text(gift?.emoji ?? '🎁', style: const TextStyle(fontSize: 30)),
        if (m.attachmentPath != null)
          Padding(
            padding: EdgeInsets.only(bottom: m.body == null ? 0 : 6),
            child: m.attachmentUrl == null
                ? Container(
                    width: 200,
                    height: 160,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                    child: m.attachmentPath!.toLowerCase().endsWith('.pdf')
                        ? const Icon(Icons.picture_as_pdf_rounded, color: Colors.white54)
                        : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        body: InteractiveViewer(child: Center(child: SafeImage(urlOrPath: m.attachmentUrl, fit: BoxFit.contain))),
                      ),
                    )),
                    child: SafeImage(urlOrPath: m.attachmentUrl, width: 220, height: 220, borderRadius: BorderRadius.circular(12)),
                  ),
          ),
        if (m.body != null) Text(m.body!, style: TextStyle(color: mine ? Colors.black : Colors.white, fontSize: 15, height: 1.35)),
      ]);
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: m.failed ? onRetry : null,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: m.gift != null && m.body == null ? AppColors.darkSurface2 : (mine ? AppColors.gold : AppColors.darkSurface2),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 6),
                bottomRight: Radius.circular(mine ? 6 : 20),
              ),
              border: m.failed ? Border.all(color: AppColors.error) : null,
            ),
            child: Opacity(opacity: m.pending ? .6 : 1, child: content),
          ),
        ),
        if (m.failed)
          const Text('Not sent — tap to retry', style: TextStyle(color: AppColors.error, fontSize: 11))
        else if (showRead || m.pending)
          Text(
            m.pending ? 'Sending…' : (m.readAt != null ? 'Seen ${clockTime(m.readAt!)}' : clockTime(m.createdAt)),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
      ]),
    );
  }
}
