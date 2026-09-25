class UserProfile {
  final String displayName;
  final String pronouns;
  final String lookingFor;
  final List<String> interests;
  final String bio;

  UserProfile({
    required this.displayName,
    required this.pronouns,
    required this.lookingFor,
    required this.interests,
    required this.bio,
  });

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'pronouns': pronouns,
      'looking_for': lookingFor,
      'interests': interests,
      'bio': bio,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      displayName: map['display_name'] ?? '',
      pronouns: map['pronouns'] ?? '',
      lookingFor: map['looking_for'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      bio: map['bio'] ?? '',
    );
  }
}
