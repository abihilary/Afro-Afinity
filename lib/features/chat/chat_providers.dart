import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/state/providers.dart';
import '../../core/state/session.dart';
import '../../core/util/json.dart';
import '../../models/conversation.dart';

class ConversationList {
  const ConversationList(this.items, this.unreadTotal);
  final List<Conversation> items;
  final int unreadTotal;
}

/// `GET /conversations`. Only verified members have threads; for everyone
/// else this is an empty list rather than a 403.
final conversationsProvider = FutureProvider<ConversationList>((ref) async {
  ref.watch(userIdProvider);
  final me = await ref.watch(meProvider.future);
  if (me == null || !me.canInteract) return const ConversationList([], 0);
  final j = await ref.read(apiClientProvider).getJson('/conversations');
  return ConversationList(asMapList(j['items']).map(Conversation.new).toList(), asInt(j['unread_total']) ?? 0);
});
