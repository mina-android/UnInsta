class InstagramUser {
  final String username;
  final String? displayName;
  final String? date;
  final String url;
  final DateTime? parsedDate;

  const InstagramUser({
    required this.username,
    this.displayName,
    this.date,
    required this.url,
    this.parsedDate,
  });

  factory InstagramUser.create({
    required String username,
    String? displayName,
    String? date,
  }) {
    final cleanUsername = username.trim().replaceAll('@', '');
    final cleanDate = (date != null && date.trim().isNotEmpty) ? date.trim() : null;
    return InstagramUser(
      username: cleanUsername,
      displayName: (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : null,
      date: cleanDate,
      url: 'https://www.instagram.com/$cleanUsername',
      parsedDate: parseDate(cleanDate),
    );
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final clean = dateStr.trim();
    // Parse formats like: Sep 18, 2026 2:50 am
    final m = RegExp(
      r'([A-Za-z]{3})\s+(\d{1,2}),\s+(\d{4})\s+(\d{1,2}):(\d{2})\s+([ap]m)',
      caseSensitive: false,
    ).firstMatch(clean);

    if (m != null) {
      const months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      final month = months[m.group(1)!.toLowerCase()] ?? 1;
      final day = int.tryParse(m.group(2)!) ?? 1;
      final year = int.tryParse(m.group(3)!) ?? 2000;
      var hour = int.tryParse(m.group(4)!) ?? 0;
      final minute = int.tryParse(m.group(5)!) ?? 0;
      final isPm = m.group(6)!.toLowerCase() == 'pm';

      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    }

    return DateTime.tryParse(clean);
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'date': date,
        'url': url,
        'parsedDate': parsedDate?.toIso8601String(),
      };

  factory InstagramUser.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String;
    final displayName = json['displayName'] as String?;
    final date = json['date'] as String?;
    final parsedDateStr = json['parsedDate'] as String?;
    return InstagramUser(
      username: username,
      displayName: displayName,
      date: date,
      url: json['url'] as String? ?? 'https://www.instagram.com/$username',
      parsedDate: parsedDateStr != null ? DateTime.tryParse(parsedDateStr) : parseDate(date),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstagramUser &&
          runtimeType == other.runtimeType &&
          username.toLowerCase() == other.username.toLowerCase();

  @override
  int get hashCode => username.toLowerCase().hashCode;
}

class AnalysisResult {
  final List<InstagramUser> followers;
  final List<InstagramUser> following;
  final List<InstagramUser> notFollowingBack;
  final List<InstagramUser> fans;
  final List<InstagramUser> mutual;
  final List<InstagramUser> pendingRequests;
  final List<InstagramUser> recentlyUnfollowedByMe;
  final String? accountOwner;
  final String? exportDate;

  const AnalysisResult({
    required this.followers,
    required this.following,
    required this.notFollowingBack,
    required this.fans,
    required this.mutual,
    required this.pendingRequests,
    this.recentlyUnfollowedByMe = const [],
    this.accountOwner,
    this.exportDate,
  });

  Map<String, dynamic> toJson() => {
        'accountOwner': accountOwner,
        'exportDate': exportDate,
        'followers': followers.map((u) => u.toJson()).toList(),
        'following': following.map((u) => u.toJson()).toList(),
        'notFollowingBack': notFollowingBack.map((u) => u.toJson()).toList(),
        'fans': fans.map((u) => u.toJson()).toList(),
        'mutual': mutual.map((u) => u.toJson()).toList(),
        'pendingRequests': pendingRequests.map((u) => u.toJson()).toList(),
        'recentlyUnfollowedByMe':
            recentlyUnfollowedByMe.map((u) => u.toJson()).toList(),
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    List<InstagramUser> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => InstagramUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return AnalysisResult(
      accountOwner: json['accountOwner'] as String?,
      exportDate: json['exportDate'] as String?,
      followers: parseList(json['followers']),
      following: parseList(json['following']),
      notFollowingBack: parseList(json['notFollowingBack']),
      fans: parseList(json['fans']),
      mutual: parseList(json['mutual']),
      pendingRequests: parseList(json['pendingRequests']),
      recentlyUnfollowedByMe: parseList(json['recentlyUnfollowedByMe']),
    );
  }
}

class ComparisonResult {
  final String? previousExportDate;
  final String? currentExportDate;
  final List<InstagramUser> lostFollowers; // People who unfollowed you
  final List<InstagramUser> unfollowedByMe; // People you unfollowed
  final List<InstagramUser> newFollowers; // New people following you
  final List<InstagramUser> newFollowing; // New people you followed
  final bool hasComparison;

  const ComparisonResult({
    this.previousExportDate,
    this.currentExportDate,
    required this.lostFollowers,
    required this.unfollowedByMe,
    required this.newFollowers,
    required this.newFollowing,
    required this.hasComparison,
  });
}
