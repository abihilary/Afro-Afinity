import '../core/util/json.dart';

/// Member status, as `/me` reports it. Routing is decided on this alone.
enum MemberStatus { onboarding, pending, active, suspended, deleted, unknown }

MemberStatus parseStatus(Object? v) => switch (v) {
      'onboarding' => MemberStatus.onboarding,
      'pending' => MemberStatus.pending,
      'active' => MemberStatus.active,
      'suspended' => MemberStatus.suspended,
      'deleted' => MemberStatus.deleted,
      _ => MemberStatus.unknown,
    };

class Photo {
  const Photo({required this.id, required this.path, required this.sort, this.url});
  final String id;
  final String path;
  final int sort;
  final String? url;

  factory Photo.fromJson(Json j) => Photo(
        id: asString(j['id']) ?? '',
        path: asString(j['path']) ?? '',
        sort: asInt(j['sort']) ?? 0,
        url: asString(j['url']),
      );
}

class Prompt {
  const Prompt(this.q, this.a);
  final String q;
  final String a;
  factory Prompt.fromJson(Json j) => Prompt(asString(j['q']) ?? '', asString(j['a']) ?? '');
  Json toJson() => {'q': q, 'a': a};
}

class Verification {
  const Verification({required this.status, this.note, this.createdAt, this.reviewedAt});
  /// pending | approved | rejected
  final String status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  factory Verification.fromJson(Json j) => Verification(
        status: asString(j['status']) ?? 'pending',
        note: asString(j['note']),
        createdAt: asDate(j['created_at']),
        reviewedAt: asDate(j['reviewed_at']),
      );
}

class Subscription {
  const Subscription({required this.planCode, this.period, this.status, this.currentPeriodEnd});
  final String planCode;
  final String? period;
  final String? status;
  final DateTime? currentPeriodEnd;

  bool get active =>
      status != 'expired' && currentPeriodEnd != null && currentPeriodEnd!.isAfter(DateTime.now());

  factory Subscription.fromJson(Json j) => Subscription(
        planCode: asString(j['plan_code']) ?? '',
        period: asString(j['period']),
        status: asString(j['status']),
        currentPeriodEnd: asDate(j['current_period_end']),
      );
}

/// The perk keys the API knows. Anything else in `perks` is ignored.
class Perks {
  const Perks(this.raw);
  final Map<String, bool> raw;
  bool get incognito => raw['incognito'] ?? false;
  bool get seeLikes => raw['see_likes'] ?? false;
  bool get unlimitedLikes => raw['unlimited_likes'] ?? false;
  bool get freeUnlocks => raw['free_unlocks'] ?? false;
  bool get advancedSearch => raw['advanced_search'] ?? false;

  factory Perks.fromJson(Object? v) =>
      Perks(asMap(v).map((k, val) => MapEntry(k, asBool(val))));
}

/// Everything `GET /me` returns. Cached in `meProvider` and replaced whole
/// after every mutation that returns it (PATCH /me, PUT /me/photos, …).
class Me {
  Me(this.raw)
      : userId = asString(raw['user_id']) ?? '',
        username = asString(raw['username']),
        displayName = asString(raw['display_name']),
        birthDate = asString(raw['birth_date']),
        gender = asString(raw['gender']),
        seeking = asStringList(raw['seeking']),
        bio = asString(raw['bio']),
        city = asString(raw['city']),
        countryCode = asString(raw['country_code']),
        region = asString(raw['region']),
        tribe = asString(raw['tribe']),
        religion = asString(raw['religion']),
        goal = asString(raw['goal']),
        heightCm = asInt(raw['height_cm']),
        languages = asStringList(raw['languages']),
        interests = asStringList(raw['interests']),
        prompts = asMapList(raw['prompts']).map(Prompt.fromJson).toList(),
        avatarUrl = asString(raw['avatar_url']),
        bannerUrl = asString(raw['banner_url']),
        audioUrl = asString(raw['audio_url']),
        audioPath = asString(raw['audio_prompt_path']),
        verifiedAt = asDate(raw['verified_at']),
        incognito = asBool(raw['incognito']),
        boostedUntil = asDate(raw['boosted_until']),
        locale = asString(raw['locale']) ?? 'en',
        status = parseStatus(raw['status']),
        onboardingStep = asInt(raw['onboarding_step']) ?? 0,
        zodiac = asString(raw['zodiac']),
        photos = asMapList(raw['photos']).map(Photo.fromJson).toList()
          ..sort((a, b) => a.sort.compareTo(b.sort)),
        balance = asInt(asMap(raw['wallet'])['balance']) ?? 0,
        earned = asInt(asMap(raw['wallet'])['earned']) ?? 0,
        plus = asBool(raw['plus']),
        perks = Perks.fromJson(raw['perks']),
        subscription = raw['subscription'] is Map ? Subscription.fromJson(asMap(raw['subscription'])) : null,
        verification = raw['verification'] is Map ? Verification.fromJson(asMap(raw['verification'])) : null,
        matchCount = asInt(asMap(raw['stats'])['matches']) ?? 0,
        likesReceived = asInt(asMap(raw['stats'])['likes_received']) ?? 0,
        currency = asString(raw['currency']) ?? 'XAF';

  final Json raw;
  final String userId;
  final String? username;
  final String? displayName;
  final String? birthDate;
  final String? gender;
  final List<String> seeking;
  final String? bio;
  final String? city;
  final String? countryCode;
  final String? region;
  final String? tribe;
  final String? religion;
  final String? goal;
  final int? heightCm;
  final List<String> languages;
  final List<String> interests;
  final List<Prompt> prompts;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? audioUrl;
  final String? audioPath;
  final DateTime? verifiedAt;
  final bool incognito;
  final DateTime? boostedUntil;
  final String locale;
  final MemberStatus status;
  final int onboardingStep;
  final String? zodiac;
  final List<Photo> photos;
  final int balance;
  final int earned;
  final bool plus;
  final Perks perks;
  final Subscription? subscription;
  final Verification? verification;
  final int matchCount;
  final int likesReceived;
  final String currency;

  /// The API's own gate (`requireVerified`): verified *and* active.
  bool get canInteract => verifiedAt != null && status == MemberStatus.active;

  bool get boosted => boostedUntil != null && boostedUntil!.isAfter(DateTime.now());

  int? get age {
    final d = birthDate == null ? null : DateTime.tryParse(birthDate!);
    if (d == null) return null;
    final now = DateTime.now();
    var a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return a;
  }

  /// A structured attribute (eye_color, smoker, …) by field name.
  String? attribute(String field) => asString(raw[field]);

  /// 0–100, the same fields the web profile meter counts.
  int get completion {
    final checks = <bool>[
      photos.isNotEmpty,
      photos.length >= 3,
      (bio ?? '').length >= 20,
      interests.length >= 3,
      prompts.isNotEmpty,
      audioPath != null,
      goal != null,
      languages.isNotEmpty,
      heightCm != null,
      verifiedAt != null,
    ];
    return (checks.where((c) => c).length * 100 / checks.length).round();
  }
}
