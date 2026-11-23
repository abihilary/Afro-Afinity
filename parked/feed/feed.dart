class FeedLocation {
  final String city;
  final String country;

  const FeedLocation({
    required this.city,
    required this.country,
  });

  String get formatted => '$city, $country';

  Map<String, dynamic> toJson() => {
        'city': city,
        'country': country,
      };

  factory FeedLocation.fromJson(Map<String, dynamic> json) => FeedLocation(
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
      );
}

class FeedMedia {
  final String id;
  final String type; // 'image' | 'video'
  final String url;
  final String thumbnailUrl;
  final int position;
  final int width;
  final int height;

  const FeedMedia({
    required this.id,
    required this.type,
    required this.url,
    required this.thumbnailUrl,
    this.position = 0,
    this.width = 1080,
    this.height = 1350,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'position': position,
        'width': width,
        'height': height,
      };

  factory FeedMedia.fromJson(Map<String, dynamic> json) => FeedMedia(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'image',
        url: json['url'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        position: json['position'] as int? ?? 0,
        width: json['width'] as int? ?? 1080,
        height: json['height'] as int? ?? 1350,
      );
}

class FeedPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final bool isAuthorVerified;
  final String type; // 'photo' | 'text'
  final String caption;
  final List<FeedMedia> media;
  final FeedLocation location;
  final String visibility; // 'public' | 'private'
  final bool commentsEnabled;
  int likeCount;
  int commentCount;
  int shareCount;
  bool isLiked;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.isAuthorVerified = true,
    required this.type,
    required this.caption,
    required this.media,
    required this.location,
    this.visibility = 'public',
    this.commentsEnabled = true,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'isAuthorVerified': isAuthorVerified,
        'type': type,
        'caption': caption,
        'media': media.map((m) => m.toJson()).toList(),
        'location': location.toJson(),
        'visibility': visibility,
        'commentsEnabled': commentsEnabled,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'shareCount': shareCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
