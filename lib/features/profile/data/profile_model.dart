class TrashItem {
  final String name;
  final int count;

  TrashItem({
    required this.name,
    required this.count,
  });

  factory TrashItem.fromJson(Map<String, dynamic> json) {
    return TrashItem(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
      };
}

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final bool isCompany;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.isCompany,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      isCompany: json['is_company'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profile_image_url': profileImageUrl,
        'is_company': isCompany,
      };
}

class ProfileStats {
  final UserProfile user;
  final int sessionsCompleted;
  final int rewardsClaimed;
  final int pointsAvailable;
  final int pointsEarnedTotal;
  final int pointsEarnedLastMonth;
  final List<TrashItem> trashItemsByType;

  ProfileStats({
    required this.user,
    required this.sessionsCompleted,
    required this.rewardsClaimed,
    required this.pointsAvailable,
    required this.pointsEarnedTotal,
    required this.pointsEarnedLastMonth,
    required this.trashItemsByType,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ProfileStats(
      user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
      sessionsCompleted: data['sessions_completed'] as int,
      rewardsClaimed: data['rewards_claimed'] as int,
      pointsAvailable: data['points_available'] as int,
      pointsEarnedTotal: data['points_earned_total'] as int,
      pointsEarnedLastMonth: data['points_earned_last_month'] as int,
      trashItemsByType: (data['trash_items_by_type'] as List<dynamic>)
          .map((item) => TrashItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'user': user.toJson(),
          'sessions_completed': sessionsCompleted,
          'rewards_claimed': rewardsClaimed,
          'points_available': pointsAvailable,
          'points_earned_total': pointsEarnedTotal,
          'points_earned_last_month': pointsEarnedLastMonth,
          'trash_items_by_type':
              trashItemsByType.map((item) => item.toJson()).toList(),
        },
      };
}
