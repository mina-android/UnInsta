import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class InstagramAvatarService {
  static final InstagramAvatarService _instance = InstagramAvatarService._internal();
  factory InstagramAvatarService() => _instance;
  InstagramAvatarService._internal();

  /// In-memory cache of username -> avatar URL (or null if unavailable)
  static final Map<String, String?> _memoryCache = {};

  /// In-flight requests deduplication
  static final Map<String, Future<String?>> _inFlight = {};

  /// Max concurrent HTTP requests
  static const int _maxConcurrent = 4;
  static int _activeRequests = 0;
  static final List<void Function()> _requestQueue = [];

  static SharedPreferences? _prefs;

  /// Returns synchronous avatar URL from in-memory cache if available.
  static String? getCachedAvatarUrl(String username) {
    final clean = _cleanUsername(username);
    return _memoryCache[clean];
  }

  /// Checks if the avatar has already been fetched or attempted in memory.
  static bool hasCached(String username) {
    final clean = _cleanUsername(username);
    return _memoryCache.containsKey(clean);
  }

  static String _cleanUsername(String username) {
    return username.trim().toLowerCase().replaceAll('@', '');
  }

  /// Layer 2: Public proxy avatar URL as secondary fallback before local monogram.
  static String getProxyAvatarUrl(String username) {
    final clean = _cleanUsername(username);
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(clean)}&background=833AB4&color=ffffff&size=128&bold=true';
  }

  /// Resolves the avatar URL for a given Instagram username.
  /// Tier 1: Local cache -> Tier 1.1 Web API -> Tier 1.2 OpenGraph -> Tier 2 Proxy
  static Future<String?> getAvatarUrl(String username) async {
    final clean = _cleanUsername(username);
    if (clean.isEmpty) return null;

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(clean)) {
      return _memoryCache[clean];
    }

    // 2. Check if a request is already in-flight for this user
    if (_inFlight.containsKey(clean)) {
      return _inFlight[clean];
    }

    // 3. Initiate lookup
    final future = _resolveAvatar(clean);
    _inFlight[clean] = future;

    try {
      final result = await future;
      _memoryCache[clean] = result;
      return result;
    } catch (_) {
      // Fall back to Layer 2 proxy
      final proxyUrl = getProxyAvatarUrl(clean);
      _memoryCache[clean] = proxyUrl;
      return proxyUrl;
    } finally {
      _inFlight.remove(clean);
    }
  }

  static Future<String?> _resolveAvatar(String cleanUsername) async {
    // 1. Check persistent SharedPreferences cache
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final cachedUrl = _prefs?.getString('ig_avatar_$cleanUsername');
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        return cachedUrl;
      }
    } catch (_) {}

    // 2. Fetch from Instagram via API / OpenGraph with concurrency limit
    return _enqueueRequest(() => _fetchFromInstagram(cleanUsername));
  }

  static Future<T> _enqueueRequest<T>(Future<T> Function() task) {
    final completer = Completer<T>();

    void execute() async {
      _activeRequests++;
      try {
        final res = await task();
        completer.complete(res);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _activeRequests--;
        if (_requestQueue.isNotEmpty) {
          final next = _requestQueue.removeAt(0);
          next();
        }
      }
    }

    if (_activeRequests < _maxConcurrent) {
      execute();
    } else {
      _requestQueue.add(execute);
    }

    return completer.future;
  }

  static Future<String?> _fetchFromInstagram(String cleanUsername) async {
    // Layer 1.A: Instagram Web Profile API
    final apiResult = await _fetchViaWebProfileApi(cleanUsername);
    if (apiResult != null) {
      await _cacheUrl(cleanUsername, apiResult);
      return apiResult;
    }

    // Layer 1.B: Instagram OpenGraph Crawler
    final ogResult = await _fetchViaOpenGraph(cleanUsername);
    if (ogResult != null) {
      await _cacheUrl(cleanUsername, ogResult);
      return ogResult;
    }

    // Layer 2: Public Proxy Avatar Fallback
    final proxyUrl = getProxyAvatarUrl(cleanUsername);
    return proxyUrl;
  }

  static Future<void> _cacheUrl(String cleanUsername, String url) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString('ig_avatar_$cleanUsername', url);
    } catch (_) {}
  }

  static Future<String?> _fetchViaWebProfileApi(String cleanUsername) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse(
        'https://www.instagram.com/api/v1/users/web_profile_info/?username=$cleanUsername',
      );
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 4));

      req.headers.set('x-ig-app-id', '936619743392459');
      req.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      );
      req.headers.set(HttpHeaders.acceptHeader, '*/*');
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');

      final res = await req.close().timeout(const Duration(seconds: 4));
      if (res.statusCode == HttpStatus.ok) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final user = json['data']?['user'] as Map<String, dynamic>?;
        final picHd = user?['profile_pic_url_hd'] as String?;
        final picRegular = user?['profile_pic_url'] as String?;
        final url = picHd ?? picRegular;
        if (url != null && url.startsWith('http')) {
          return url.replaceAll('&amp;', '&');
        }
      }
    } catch (_) {
      // Ignore API errors, try next fallback
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  static Future<String?> _fetchViaOpenGraph(String cleanUsername) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final uri = Uri.parse('https://www.instagram.com/$cleanUsername/');
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 4));

      req.headers.set(
        HttpHeaders.userAgentHeader,
        'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
      );
      req.headers.set(HttpHeaders.acceptHeader, 'text/html,application/xhtml+xml');
      req.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');

      final res = await req.close().timeout(const Duration(seconds: 4));
      if (res.statusCode == HttpStatus.ok) {
        final body = await res.transform(utf8.decoder).join();
        final match = RegExp(
          r'property=[\x22\x27]og:image[\x22\x27]\s+content=[\x22\x27]([^\x22\x27]+)[\x22\x27]|content=[\x22\x27]([^\x22\x27]+)[\x22\x27]\s+property=[\x22\x27]og:image[\x22\x27]',
          caseSensitive: false,
        ).firstMatch(body);

        final foundUrl = match?.group(1) ?? match?.group(2);
        if (foundUrl != null && foundUrl.startsWith('https://')) {
          return foundUrl.replaceAll('&amp;', '&');
        }
      }
    } catch (_) {
      // Ignore crawler errors
    } finally {
      client?.close(force: true);
    }
    return null;
  }
}
