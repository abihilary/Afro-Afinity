import '../core/util/json.dart';
import 'me.dart';

/// Another member as a list row or a deck card. Discover, search, directory,
/// likes, views, matches, favourites, friends and blocks all return a subset
/// of these keys, so every field is optional.
class MemberCard {
  MemberCard(this.raw)
      : userId = asString(raw['user_id']) ?? '',
        username = asString(raw['username']),
        displayName = asString(raw['display_name']),
        age = asInt(raw['age']),
        gender = asString(raw['gender']),
        city = asString(raw['city']),
        countryCode = asString(raw['country_code']),
        tribe = asString(raw['tribe']),
        bio = asString(raw['bio']),
        interests = asStringList(raw['interests']),
        avatarUrl = asString(raw['avatar_url']),
        verified = asBool(raw['verified']),
        online = asBool(raw['online']),
        boosted = asBool(raw['boosted']),
        distanceKm = asDouble(raw['distance_km']),
        myLike = asString(raw['my_like']),
        likedMe = asBool(raw['liked_me']),
        matched = asBool(raw['matched']),
        blurred = asBool(raw['blurred']);

  final Json raw;
  final String userId;
  final String? username;
  final String? displayName;
  final int? age;
  final String? gender;
  final String? city;
  final String? countryCode;
  final String? tribe;
  final String? bio;
  final List<String> interests;
  final String? avatarUrl;
  final bool verified;
  final bool online;
  final bool boosted;
  /// Already rounded by the server. Never compute distance on the device.
  final double? distanceKm;
  final String? myLike;
  final bool likedMe;
  final bool matched;
  /// Server-side redaction for members without the `see_likes` perk.
  final bool blurred;

  String get name => displayName ?? username ?? 'Member';

  String get place => [city, countryCode].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  String? get distanceLabel {
    final d = distanceKm;
    if (d == null) return null;
    return d < 1 ? 'Less than 1 km away' : '${d.round()} km away';
  }
}

class Relation {
  const Relation({this.myLike, this.likedMe = false, this.favorite = false, this.matched = false, this.conversationId});
  final String? myLike;
  final bool likedMe;
  final bool favorite;
  final bool matched;
  final String? conversationId;

  factory Relation.fromJson(Json j) => Relation(
        myLike: asString(j['my_like']),
        likedMe: asBool(j['liked_me']),
        favorite: asBool(j['favorite']),
        matched: asBool(j['matched']),
        conversationId: asString(j['conversation_id']),
      );

  Relation copyWith({String? myLike, bool? favorite, bool? matched, String? conversationId}) => Relation(
        myLike: myLike ?? this.myLike,
        likedMe: likedMe,
        favorite: favorite ?? this.favorite,
        matched: matched ?? this.matched,
        conversationId: conversationId ?? this.conversationId,
      );
}

/// `GET /profiles/:username` — the full card plus how the viewer relates to it.
class PublicProfile {
  PublicProfile(Json body)
      : card = MemberCard(asMap(body['profile'])),
        profile = asMap(body['profile']),
        relation = Relation.fromJson(asMap(body['relation'])),
        teaser = asBool(body['teaser']);

  final MemberCard card;
  final Json profile;
  final Relation relation;
  final bool teaser;

  List<Photo> get photos => asMapList(profile['photos']).map(Photo.fromJson).toList()
    ..sort((a, b) => a.sort.compareTo(b.sort));
  List<Prompt> get prompts => asMapList(profile['prompts']).map(Prompt.fromJson).toList();
  List<String> get languages => asStringList(profile['languages']);
  List<String> get seeking => asStringList(profile['seeking']);
  String? get audioUrl => asString(profile['audio_url']);
  String? get bannerUrl => asString(profile['banner_url']);
  String? get goal => asString(profile['goal']);
  String? get religion => asString(profile['religion']);
  String? get zodiac => asString(profile['zodiac']);
  int? get heightCm => asInt(profile['height_cm']);
  DateTime? get lastSeen => asDate(profile['last_seen_at']);
  String? attribute(String field) => asString(profile[field]);
}

/// A row from a connections list that wraps a member: matches carry
/// `profile`, gifts carry `person`, friends/winks/likes are flat.
class ConnectionRow {
  ConnectionRow(this.raw)
      : member = MemberCard(raw['profile'] is Map
            ? asMap(raw['profile'])
            : raw['person'] is Map
                ? asMap(raw['person'])
                : raw),
        at = asDate(raw['matched_at'] ?? raw['liked_at'] ?? raw['seen_at'] ?? raw['last_wink'] ?? raw['since'] ?? raw['created_at']),
        winkCount = asInt(raw['wink_count']),
        winkedBack = asBool(raw['winked_back']),
        giftEmoji = asString(asMap(raw['gift'])['emoji']),
        giftLabel = asString(asMap(raw['gift'])['label_en']),
        coins = asInt(raw['coins']),
        conversationId = asString(raw['conversation_id']),
        kind = asString(raw['kind']),
        viewCount = asInt(raw['view_count']),
        message = asString(raw['message']);

  final Json raw;
  final MemberCard member;
  final DateTime? at;
  final String? conversationId;
  final String? kind;
  final int? viewCount;
  final String? message;
  final int? winkCount;
  final bool winkedBack;
  final String? giftEmoji;
  final String? giftLabel;
  final int? coins;
}
