import '../core/util/json.dart';

class MessageGift {
  const MessageGift({required this.code, this.coins});
  final String code;
  final int? coins;
}

class Message {
  Message({
    required this.id,
    required this.senderId,
    this.body,
    this.attachmentPath,
    this.attachmentUrl,
    this.gift,
    required this.createdAt,
    this.readAt,
    required this.mine,
    this.pending = false,
    this.failed = false,
  });

  final String id;
  final String? senderId;
  final String? body;
  final String? attachmentPath;
  final String? attachmentUrl;
  final MessageGift? gift;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool mine;
  /// Local-only states for an optimistic send.
  final bool pending;
  final bool failed;

  bool get isGift => gift != null || (body == null && attachmentPath == null);

  /// From the API, or from a realtime row (which has no `mine` and no signed
  /// URL), so `myId` decides ownership when the payload does not.
  factory Message.fromJson(Json j, {required String myId}) {
    final g = j['gift'];
    return Message(
      id: asString(j['id']) ?? '',
      senderId: asString(j['sender_id']),
      body: asString(j['body']),
      attachmentPath: asString(j['attachment_path']),
      attachmentUrl: asString(j['attachment_url']),
      gift: g is Map
          ? MessageGift(code: asString(g['gift_code']) ?? '', coins: asInt(g['coins']))
          : (j['gift_send_id'] != null ? const MessageGift(code: '') : null),
      createdAt: asDate(j['created_at']) ?? DateTime.now(),
      readAt: asDate(j['read_at']),
      mine: j['mine'] is bool ? j['mine'] as bool : asString(j['sender_id']) == myId,
    );
  }

  Message copyWith({String? id, bool? pending, bool? failed, String? attachmentUrl}) => Message(
        id: id ?? this.id,
        senderId: senderId,
        body: body,
        attachmentPath: attachmentPath,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        gift: gift,
        createdAt: createdAt,
        readAt: readAt,
        mine: mine,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );
}
