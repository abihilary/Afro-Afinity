import 'package:flutter/foundation.dart';

import 'profile.dart';

class LikesStore extends ChangeNotifier {
  LikesStore._();

  static final LikesStore instance = LikesStore._();

  final List<DiscoverProfile> _likes = [];

  List<DiscoverProfile> get likes => List.unmodifiable(_likes);

  void add(DiscoverProfile profile) {
    if (_likes.any((item) => item.id == profile.id)) return;
    _likes.add(profile);
    notifyListeners();
  }

  void remove(DiscoverProfile profile) {
    _likes.removeWhere((item) => item.id == profile.id);
    notifyListeners();
  }
}
