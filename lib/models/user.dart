import 'package:flutter/foundation.dart';

class AppUser extends ChangeNotifier {
  AppUser._();

  static final AppUser instance = AppUser._();

  String name = 'Kofi';
  int age = 26;
  String handle = '@hilarysw';
  String location = '🇬🇭 Accra, Ghana';
  String height = '5\'10"';
  String job = 'Afrobeats Producer @ Accra';
  String education = 'B.A. Music, Legon';
  String pronouns = 'He/Him';
  String bio =
      'Jollof critic, Ankara collector. My village is Aburi - best palm wine. Looking for someone who knows Waakye > Jollof.';
  String? profileImagePath;
  String? bannerImagePath;
  String bannerGradientStyle = 'Pink Violet';
  bool hasPatternMesh = true;

  bool isVerified = true;
  bool isPremium = true;
  bool notificationsEnabled = true;
  bool showDistance = true;
  bool incognitoMode = false;

  int walletCoins = 1250;
  String userLevel = 'Level 4 • Explorer';
  double levelProgress = 0.62;

  String promptQuestion = 'I’m convinced that...';
  String promptAnswer =
      'The best conversations happen on night walks, not over text.';

  final List<String> photos = [
    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&q=80&auto=format&fit=crop',
  ];

  final List<String> interests = [
    'Architecture',
    'Climbing',
    'Natural wine',
    'Film photo',
    'Design',
    'Cycling',
    'Museums',
    'Jazz',
  ];

  int get completionPercentage {
    int score = 0;
    if (photos.isNotEmpty || profileImagePath != null) score += 30;
    if (photos.length >= 3) score += 20;
    if (bio.isNotEmpty) score += 15;
    if (promptAnswer.isNotEmpty) score += 15;
    if (interests.isNotEmpty) score += 10;
    if (isVerified) score += 10;
    return score.clamp(0, 100);
  }

  void updateProfile({
    String? name,
    int? age,
    String? handle,
    String? location,
    String? height,
    String? job,
    String? education,
    String? pronouns,
    String? bio,
    String? promptQuestion,
    String? promptAnswer,
    String? profileImagePath,
  }) {
    if (name != null) this.name = name;
    if (age != null) this.age = age;
    if (handle != null) this.handle = handle;
    if (location != null) this.location = location;
    if (height != null) this.height = height;
    if (job != null) this.job = job;
    if (education != null) this.education = education;
    if (pronouns != null) this.pronouns = pronouns;
    if (bio != null) this.bio = bio;
    if (promptQuestion != null) this.promptQuestion = promptQuestion;
    if (promptAnswer != null) this.promptAnswer = promptAnswer;

    if (profileImagePath != null) {
      this.profileImagePath = profileImagePath;
      if (!photos.contains(profileImagePath)) {
        photos.insert(0, profileImagePath);
      }
    }

    notifyListeners();
  }

  void setBannerPhoto(String? path) {
    bannerImagePath = path;
    notifyListeners();
  }

  void setBannerGradient(String style) {
    bannerGradientStyle = style;
    bannerImagePath = null;
    notifyListeners();
  }

  void togglePatternMesh(bool enable) {
    hasPatternMesh = enable;
    notifyListeners();
  }

  void removeBanner() {
    bannerImagePath = null;
    bannerGradientStyle = 'Pink Violet';
    hasPatternMesh = false;
    notifyListeners();
  }

  void addCoins(int count) {
    walletCoins += count;
    notifyListeners();
  }

  void addPhoto(String path) {
    if (photos.length < 6) {
      photos.add(path);
      profileImagePath ??= path;
      notifyListeners();
    }
  }

  void removePhotoAt(int index) {
    if (index >= 0 && index < photos.length) {
      final removed = photos.removeAt(index);
      if (profileImagePath == removed) {
        profileImagePath = photos.isNotEmpty ? photos.first : null;
      }
      notifyListeners();
    }
  }

  void clearProfileImage() {
    profileImagePath = null;
    if (photos.isNotEmpty) {
      photos.removeAt(0);
    }
    notifyListeners();
  }

  void replaceInterests(Iterable<String> values) {
    interests
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  void updatePreferences({
    bool? notificationsEnabled,
    bool? showDistance,
    bool? incognitoMode,
  }) {
    if (notificationsEnabled != null) {
      this.notificationsEnabled = notificationsEnabled;
    }
    if (showDistance != null) this.showDistance = showDistance;
    if (incognitoMode != null) this.incognitoMode = incognitoMode;
    notifyListeners();
  }

  void verifyProfile() {
    isVerified = true;
    notifyListeners();
  }
}
