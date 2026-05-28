class RankingEntry {
  final int id;
  final String username;
  final String name;
  final String? profileImageUrl;
  final String points;

  RankingEntry({
    required this.id,
    required this.username,
    required this.name,
    this.profileImageUrl,
    required this.points,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
      points: json['points'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'profile_image_url': profileImageUrl,
        'points': points,
      };

  double get pointsAsDouble => double.tryParse(points) ?? 0.0;

  String get displayName => name.isNotEmpty ? name : username;
}

class RankingResponse {
  final List<RankingEntry> entries;

  RankingResponse({required this.entries});

  factory RankingResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    return RankingResponse(
      entries: data
          .map((item) => RankingEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': entries.map((entry) => entry.toJson()).toList(),
      };
}
