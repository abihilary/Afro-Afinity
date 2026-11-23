import '../core/util/json.dart';
import 'member.dart';

class Conversation {
  Conversation(Json j)
      : id = asString(j['id']) ?? '',
        openedVia = asString(j['opened_via']),
        unread = asInt(j['unread']) ?? 0,
        lastMessageAt = asDate(j['last_message_at']),
        lastPreview = asString(j['last_preview']),
        other = MemberCard(asMap(j['other'])),
        otherGone = asBool(asMap(j['other'])['gone']);

  final String id;
  final String? openedVia;
  final int unread;
  final DateTime? lastMessageAt;
  final String? lastPreview;
  final MemberCard other;
  final bool otherGone;
}

/// `GET /conversations/:id` — the thread header.
class ThreadHeader {
  ThreadHeader(Json j)
      : id = asString(j['id']) ?? '',
        other = MemberCard(asMap(j['other'])),
        otherGone = asBool(asMap(j['other'])['gone']),
        blocked = asBool(j['blocked']),
        openedVia = asString(j['opened_via']),
        messagesLeft = asInt(j['messages_left']);

  final String id;
  final MemberCard other;
  final bool otherGone;
  final bool blocked;
  final String? openedVia;
  /// Only set in soft gate mode for the member who opened the thread for free.
  final int? messagesLeft;
}
