// Tolerant readers for API payloads. The API omits fields freely (a blurred
// like has no username, a gone member has no avatar), so every read here
// returns a safe value instead of throwing on a missing or mistyped key.

typedef Json = Map<String, dynamic>;

Json asMap(Object? v) => v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

List<Json> asMapList(Object? v) =>
    v is List ? v.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList() : <Json>[];

List<String> asStringList(Object? v) =>
    v is List ? v.where((e) => e != null).map((e) => e.toString()).toList() : <String>[];

String? asString(Object? v) => v?.toString();

int? asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

double? asDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool asBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true';
  return fallback;
}

DateTime? asDate(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
