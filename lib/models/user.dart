import 'package:flutter/foundation.dart';

class AppUser extends ChangeNotifier {
  AppUser._();

  static final AppUser instance = AppUser._();

  String name = 'Kofi';
  int age = 28;
  String handle = '@kofi_affinity';
  String location = 'Stuttgart, Germany';
  String height = "6'1\" (185 cm)";
  String job = 'Architect & Design Director';
  String education = 'Master\'s in Sustainable Design';
  String pronouns = 'he/him';
  String bio =
      'Passionate about modern African architecture, jazz music, and exploring hidden city spots. Looking for genuine connections rooted in culture & good energy.';
  String promptQuestion = 'My favorite Afrobeats artist is...';
  String promptAnswer =
      'Burna Boy live changed my life - but Tems has my soul. What\'s your top 3?';

  String? bannerImageUrl;
  String bannerGradientStyle = 'Pink Violet';
  bool hasPatternMesh = true;

  int walletCoins = 1250;
  int userLevel = 12;
  double levelProgress = 0.65;
  bool isVerified = true;
  bool isPremium = true;

  List<String> interests = [
    'Architecture',
    'Design',
    'Afrobeats',
    'Jazz',
    'Travel',
    'Museums',
  ];

  List<String> photos = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=900&q=90',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=900&q=90',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=90',
  ];

  void addPhoto(String path) {
    if (photos.length < 6) {
      photos.add(path);
      notifyListeners();
    }
  }

  void removePhotoAt(int index) {
    if (index >= 0 && index < photos.length && photos.length > 1) {
      photos.removeAt(index);
      notifyListeners();
    }
  }

  void updateBannerPhoto(String path) {
    bannerImageUrl = path;
    notifyListeners();
  }

  void setBannerGradientStyle(String style) {
    bannerGradientStyle = style;
    notifyListeners();
  }

  void togglePatternMesh(bool value) {
    hasPatternMesh = value;
    notifyListeners();
  }

  void removeBanner() {
    bannerImageUrl = null;
    notifyListeners();
  }

  void addCoins(int amount) {
    walletCoins += amount;
    notifyListeners();
  }
}
