import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/instagram_models.dart';

class ExportHistoryService {
  static const String _keyCurrentSnapshot = 'uninsta_current_snapshot';
  static const String _keyPreviousSnapshot = 'uninsta_previous_snapshot';
  static const String _keyCachedAnalysisResult = 'uninsta_cached_analysis_result';

  /// Saves the newly analyzed export as the current snapshot,
  /// moving the old current snapshot to previous (if different),
  /// and persists the complete AnalysisResult for instant startup retrieval.
  static Future<void> saveExportSnapshot(AnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();

    final currentRaw = prefs.getString(_keyCurrentSnapshot);
    if (currentRaw != null) {
      try {
        final currentMap = jsonDecode(currentRaw) as Map<String, dynamic>;
        final prevExportDate = currentMap['exportDate'] as String?;
        final currentExportDate = result.exportDate;

        // If the new export has a different date/owner or is not identical, move current to previous
        if (prevExportDate != currentExportDate || prevExportDate == null) {
          await prefs.setString(_keyPreviousSnapshot, currentRaw);
        }
      } catch (_) {}
    }

    final snapshotMap = {
      'cachedAt': DateTime.now().toIso8601String(),
      'accountOwner': result.accountOwner,
      'exportDate': result.exportDate,
      'followers': result.followers.map((u) => u.toJson()).toList(),
      'following': result.following.map((u) => u.toJson()).toList(),
    };

    await prefs.setString(_keyCurrentSnapshot, jsonEncode(snapshotMap));
    await prefs.setString(_keyCachedAnalysisResult, jsonEncode(result.toJson()));
  }

  /// Loads the persisted complete AnalysisResult if available.
  static Future<AnalysisResult?> loadCachedAnalysisResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyCachedAnalysisResult);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AnalysisResult.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Calculates comparison between the previous cached snapshot and current result.
  static Future<ComparisonResult> getComparison(AnalysisResult currentResult) async {
    final prefs = await SharedPreferences.getInstance();
    var prevRaw = prefs.getString(_keyPreviousSnapshot);

    // Fallback: if previous isn't set yet, check if currently cached snapshot is different from incoming result
    if (prevRaw == null) {
      final curRaw = prefs.getString(_keyCurrentSnapshot);
      if (curRaw != null) {
        try {
          final curMap = jsonDecode(curRaw) as Map<String, dynamic>;
          final curExportDate = curMap['exportDate'] as String?;
          if (curExportDate != currentResult.exportDate) {
            prevRaw = curRaw;
          }
        } catch (_) {}
      }
    }

    if (prevRaw == null) {
      return ComparisonResult(
        previousExportDate: null,
        currentExportDate: currentResult.exportDate,
        lostFollowers: const [],
        unfollowedByMe: currentResult.recentlyUnfollowedByMe,
        newFollowers: const [],
        newFollowing: const [],
        hasComparison: false,
      );
    }

    try {
      final prevMap = jsonDecode(prevRaw) as Map<String, dynamic>;
      final prevExportDate = prevMap['exportDate'] as String?;

      final prevFollowersList = (prevMap['followers'] as List<dynamic>?)
              ?.map((e) => InstagramUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final prevFollowingList = (prevMap['following'] as List<dynamic>?)
              ?.map((e) => InstagramUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final currentFollowerSet =
          currentResult.followers.map((u) => u.username.toLowerCase()).toSet();
      final currentFollowingSet =
          currentResult.following.map((u) => u.username.toLowerCase()).toSet();

      // Lost followers: in previous followers, but NOT in current followers
      final lostFollowers = prevFollowersList
          .where((u) => !currentFollowerSet.contains(u.username.toLowerCase()))
          .toList();

      // Unfollowed by me: in previous following, but NOT in current following
      final diffUnfollowedByMe = prevFollowingList
          .where((u) => !currentFollowingSet.contains(u.username.toLowerCase()))
          .toList();

      // Merge with Instagram's recorded recently_unfollowed_profiles
      final Map<String, InstagramUser> mergedUnfollowed = {};
      for (final u in diffUnfollowedByMe) {
        mergedUnfollowed[u.username.toLowerCase()] = u;
      }
      for (final u in currentResult.recentlyUnfollowedByMe) {
        mergedUnfollowed[u.username.toLowerCase()] = u;
      }

      final prevFollowerSet =
          prevFollowersList.map((u) => u.username.toLowerCase()).toSet();
      final prevFollowingSet =
          prevFollowingList.map((u) => u.username.toLowerCase()).toSet();

      // New followers
      final newFollowers = currentResult.followers
          .where((u) => !prevFollowerSet.contains(u.username.toLowerCase()))
          .toList();

      // New following
      final newFollowing = currentResult.following
          .where((u) => !prevFollowingSet.contains(u.username.toLowerCase()))
          .toList();

      return ComparisonResult(
        previousExportDate: prevExportDate,
        currentExportDate: currentResult.exportDate,
        lostFollowers: lostFollowers,
        unfollowedByMe: mergedUnfollowed.values.toList(),
        newFollowers: newFollowers,
        newFollowing: newFollowing,
        hasComparison: true,
      );
    } catch (_) {
      return ComparisonResult(
        previousExportDate: null,
        currentExportDate: currentResult.exportDate,
        lostFollowers: const [],
        unfollowedByMe: currentResult.recentlyUnfollowedByMe,
        newFollowers: const [],
        newFollowing: const [],
        hasComparison: false,
      );
    }
  }

  /// Clears stored snapshots and cached session data
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentSnapshot);
    await prefs.remove(_keyPreviousSnapshot);
    await prefs.remove(_keyCachedAnalysisResult);
  }
}
