class DiscoverProfile {
  final String id;
  final String name;
  final int age;
  final String location;
  final String distance;
  final String imageUrl;
  final String bio;
  final String prompt;
  final List<String> interests;
  final bool verified;
  final bool premium;
  final String smoking;
  final String drinking;
  final String relationshipGoal;
  final String educationLevel;

  const DiscoverProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.distance,
    required this.imageUrl,
    required this.bio,
    required this.prompt,
    required this.interests,
    this.verified = false,
    this.premium = false,
    this.smoking = 'Non-smoker',
    this.drinking = 'Social drinker',
    this.relationshipGoal = 'Long-term',
    this.educationLevel = 'Bachelor\'s',
  });
}
