import '../content/profile_content.dart';
import 'member.dart';

/// What the swipe card draws, derived from a [MemberCard]. Nothing here is
/// invented: a field the API did not send renders as absent, not as a default.
class DiscoverProfile {
  const DiscoverProfile({
    required this.card,
    required this.id,
    required this.name,
    this.age,
    required this.location,
    required this.distance,
    required this.imageUrl,
    required this.bio,
    required this.prompt,
    required this.interests,
    this.verified = false,
    this.online = false,
  });

  final MemberCard card;
  final String id;
  final String name;
  final int? age;
  final String location;
  final String distance;
  final String? imageUrl;
  final String bio;
  final String prompt;
  final List<String> interests;
  final bool verified;
  final bool online;

  factory DiscoverProfile.fromCard(MemberCard c, {String locale = 'en'}) => DiscoverProfile(
        card: c,
        id: c.userId,
        name: c.name,
        age: c.age,
        location: [c.city, if (c.countryCode != null) countryName(c.countryCode, locale)].whereType<String>().where((s) => s.isNotEmpty).join(', '),
        distance: c.distanceLabel ?? '',
        imageUrl: c.avatarUrl,
        bio: c.bio ?? '',
        prompt: '',
        interests: c.interests.map((i) => interestLabel(i, locale)).toList(),
        verified: c.verified,
        online: c.online,
      );
}
