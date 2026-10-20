// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uninsta/models/instagram_models.dart';
import 'package:uninsta/services/export_history_service.dart';
import 'package:uninsta/services/instagram_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('InstagramParserService parses real export zip with date and recently unfollowed', () async {
    final zipFile = File(r'C:\Users\minaa\Downloads\instagram-mina.ashraf.monir-2026-09-19-bUmDvk4Q.zip');
    expect(zipFile.existsSync(), isTrue);

    final bytes = await zipFile.readAsBytes();
    final result = await InstagramParserService.parseZipBytes(bytes);

    print('--- Analysis Result ---');
    print('Followers: ${result.followers.length}');
    print('Following: ${result.following.length}');
    print('Not Following Back: ${result.notFollowingBack.length}');
    print('Fans: ${result.fans.length}');
    print('Mutual: ${result.mutual.length}');
    print('Pending Requests: ${result.pendingRequests.length}');
    print('Recently Unfollowed By Me: ${result.recentlyUnfollowedByMe.length}');
    print('Account Owner: ${result.accountOwner}');
    print('Export Date: ${result.exportDate}');

    expect(result.followers.length, equals(1034));
    expect(result.following.length, equals(968));
    expect(result.notFollowingBack.length, equals(189));
    expect(result.fans.length, equals(255));
    expect(result.mutual.length, equals(779));
    expect(result.pendingRequests.length, equals(567));
    expect(result.recentlyUnfollowedByMe.length, equals(71));
    expect(result.accountOwner, equals('mina.ashraf.monir'));

    // Verify date parsing
    final sampleWithDate = result.following.firstWhere((u) => u.date != null);
    expect(sampleWithDate.parsedDate, isNotNull);
  });

  test('ExportHistoryService caches snapshot and detects comparisons', () async {
    final userA = InstagramUser.create(username: 'user_a', date: 'Sep 10, 2026 10:00 am');
    final userB = InstagramUser.create(username: 'user_b', date: 'Sep 10, 2026 10:00 am');
    final userC = InstagramUser.create(username: 'user_c', date: 'Sep 10, 2026 10:00 am');

    // Snapshot 1 (earlier)
    final export1 = AnalysisResult(
      followers: [userA, userB],
      following: [userA, userB, userC],
      notFollowingBack: [userC],
      fans: [],
      mutual: [userA, userB],
      pendingRequests: [],
      exportDate: 'Sep 10, 2026',
    );

    await ExportHistoryService.saveExportSnapshot(export1);

    // Snapshot 2 (later: userB unfollowed me, and I unfollowed userC)
    final export2 = AnalysisResult(
      followers: [userA], // userB is missing -> lost follower!
      following: [userA, userB], // userC is missing -> unfollowed by me!
      notFollowingBack: [userB],
      fans: [],
      mutual: [userA],
      pendingRequests: [],
      exportDate: 'Sep 19, 2026',
    );

    final comparison = await ExportHistoryService.getComparison(export2);
    expect(comparison.hasComparison, isTrue);
    expect(comparison.lostFollowers.length, equals(1));
    expect(comparison.lostFollowers.first.username, equals('user_b'));
    expect(comparison.unfollowedByMe.length, equals(1));
    expect(comparison.unfollowedByMe.first.username, equals('user_c'));
  });
}
