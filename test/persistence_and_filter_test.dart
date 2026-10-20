import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uninsta/models/instagram_models.dart';
import 'package:uninsta/services/export_history_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalysisResult Serialization & Persistence', () {
    test('toJson and fromJson preserves all fields with fidelity', () {
      final user1 = InstagramUser.create(
        username: 'alice',
        displayName: 'Alice Smith',
        date: 'Sep 18, 2026 2:50 am',
      );
      final user2 = InstagramUser.create(
        username: 'bob',
        displayName: 'Bob Jones',
        date: 'Jan 10, 2025 10:00 pm',
      );

      final original = AnalysisResult(
        followers: [user1, user2],
        following: [user1],
        notFollowingBack: [user1],
        fans: [user2],
        mutual: [user1],
        pendingRequests: [user2],
        recentlyUnfollowedByMe: [user2],
        accountOwner: 'testuser',
        exportDate: 'Sep 19, 2026',
      );

      final json = original.toJson();
      final restored = AnalysisResult.fromJson(json);

      expect(restored.accountOwner, equals('testuser'));
      expect(restored.exportDate, equals('Sep 19, 2026'));
      expect(restored.followers.length, equals(2));
      expect(restored.followers.first.username, equals('alice'));
      expect(restored.following.length, equals(1));
      expect(restored.notFollowingBack.length, equals(1));
      expect(restored.fans.length, equals(1));
      expect(restored.mutual.length, equals(1));
      expect(restored.pendingRequests.length, equals(1));
      expect(restored.recentlyUnfollowedByMe.length, equals(1));
    });

    test('ExportHistoryService saves and loads cached analysis', () async {
      final user = InstagramUser.create(username: 'charlie');
      final result = AnalysisResult(
        followers: [user],
        following: [user],
        notFollowingBack: [],
        fans: [],
        mutual: [user],
        pendingRequests: [],
        accountOwner: 'owner_charlie',
        exportDate: 'Oct 20, 2026',
      );

      await ExportHistoryService.saveExportSnapshot(result);

      final loaded = await ExportHistoryService.loadCachedAnalysisResult();
      expect(loaded, isNotNull);
      expect(loaded!.accountOwner, equals('owner_charlie'));
      expect(loaded.exportDate, equals('Oct 20, 2026'));
      expect(loaded.followers.length, equals(1));

      // Test clear cache
      await ExportHistoryService.clearCache();
      final afterClear = await ExportHistoryService.loadCachedAnalysisResult();
      expect(afterClear, isNull);
    });
  });
}
