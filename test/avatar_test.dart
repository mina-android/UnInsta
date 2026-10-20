import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uninsta/services/instagram_avatar_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('InstagramAvatarService fetches, returns and caches avatar URL', () async {
    final avatarUrl = await InstagramAvatarService.getAvatarUrl('instagram');
    expect(avatarUrl, isNotNull);
    expect(avatarUrl!.startsWith('https://'), isTrue);
    expect(avatarUrl.contains('scontent'), isTrue);

    // Test synchronous memory cache
    final cachedSync = InstagramAvatarService.getCachedAvatarUrl('instagram');
    expect(cachedSync, equals(avatarUrl));

    // Test second call returns cached result immediately
    final cachedAsync = await InstagramAvatarService.getAvatarUrl('instagram');
    expect(cachedAsync, equals(avatarUrl));
  });

  test('InstagramAvatarService handles clean formatting with @ symbol', () async {
    final cached = InstagramAvatarService.getCachedAvatarUrl('@instagram');
    expect(cached, isNotNull);
  });
}
