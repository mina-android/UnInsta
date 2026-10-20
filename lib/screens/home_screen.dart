import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/instagram_models.dart';
import '../services/export_history_service.dart';
import '../services/instagram_parser_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/user_card.dart';
import 'lost_followers_screen.dart';
import 'unfollowed_by_me_screen.dart';

enum ActiveTab {
  notFollowingBack,
  pendingRequests,
  fans,
  mutual,
  following,
  followers,
}

enum SortOption {
  dateDesc,
  dateAsc,
  alphabeticalAsc,
  alphabeticalDesc,
}

enum DateFilter {
  all,
  last30Days,
  last6Months,
  last1Year,
  olderThan1Year,
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AnalysisResult? _result;
  ComparisonResult? _comparison;
  bool _isLoading = false;
  bool _isFromCache = false;
  String? _errorMessage;
  String _searchQuery = '';
  ActiveTab _activeTab = ActiveTab.notFollowingBack;
  SortOption _sortOption = SortOption.dateDesc;
  DateFilter _dateFilter = DateFilter.all;
  bool _onlyMutualFilter = false;
  final TextEditingController _searchController = TextEditingController();

  static const String defaultSamplePath =
      r'C:\Users\minaa\Downloads\instagram-mina.ashraf.monir-2026-09-19-bUmDvk4Q.zip';

  @override
  void initState() {
    super.initState();
    _initAppSession();
  }

  /// Restores cached analysis session on launch; falls back to sample file if present.
  Future<void> _initAppSession() async {
    setState(() => _isLoading = true);

    try {
      final cached = await ExportHistoryService.loadCachedAnalysisResult();
      if (cached != null) {
        final comparison = await ExportHistoryService.getComparison(cached);
        if (mounted) {
          setState(() {
            _result = cached;
            _comparison = comparison;
            _isFromCache = true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickZipFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        await _processBytes(bytes);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _loadZipFromFilePath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await _processBytes(bytes);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load file: $e';
      });
    }
  }

  Future<void> _processBytes(List<int> bytes) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await InstagramParserService.parseZipBytes(bytes);

      // Get comparison with cached previous snapshot before saving new one
      final comparison = await ExportHistoryService.getComparison(res);

      // Cache this snapshot as current
      await ExportHistoryService.saveExportSnapshot(res);

      setState(() {
        _result = res;
        _comparison = comparison;
        _isFromCache = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error parsing Instagram data: $e';
      });
    }
  }

  Future<void> _clearStoredData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Saved Data?'),
        content: const Text(
          'This will remove your cached export analysis and comparison history from this device. You can import an Instagram ZIP file again at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ExportHistoryService.clearCache();
      setState(() {
        _result = null;
        _comparison = null;
        _isFromCache = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cached data cleared.')),
        );
      }
    }
  }

  List<InstagramUser> _getCurrentList() {
    if (_result == null) return [];
    switch (_activeTab) {
      case ActiveTab.notFollowingBack:
        return _result!.notFollowingBack;
      case ActiveTab.pendingRequests:
        return _result!.pendingRequests;
      case ActiveTab.fans:
        return _result!.fans;
      case ActiveTab.mutual:
        return _result!.mutual;
      case ActiveTab.following:
        return _result!.following;
      case ActiveTab.followers:
        return _result!.followers;
    }
  }

  String _getTabTitle(ActiveTab tab) {
    switch (tab) {
      case ActiveTab.notFollowingBack:
        return "Don't Follow Back";
      case ActiveTab.pendingRequests:
        return "Pending Requests";
      case ActiveTab.fans:
        return "Fans";
      case ActiveTab.mutual:
        return "Mutuals";
      case ActiveTab.following:
        return "Following";
      case ActiveTab.followers:
        return "Followers";
    }
  }

  List<InstagramUser> _getFilteredAndSortedList() {
    final list = _getCurrentList();
    var filtered = list;

    // 1. Text Search Filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        final unameMatch = u.username.toLowerCase().contains(query);
        final dnameMatch = u.displayName?.toLowerCase().contains(query) ?? false;
        return unameMatch || dnameMatch;
      }).toList();
    }

    // 2. Date Range Filter
    if (_dateFilter != DateFilter.all) {
      final now = DateTime.now();
      filtered = filtered.where((u) {
        if (u.parsedDate == null) return false;
        final diffDays = now.difference(u.parsedDate!).inDays;
        switch (_dateFilter) {
          case DateFilter.last30Days:
            return diffDays <= 30;
          case DateFilter.last6Months:
            return diffDays <= 182;
          case DateFilter.last1Year:
            return diffDays <= 365;
          case DateFilter.olderThan1Year:
            return diffDays > 365;
          case DateFilter.all:
            return true;
        }
      }).toList();
    }

    // 3. Mutual Only Filter (Relevant for Followers & Following tabs)
    if (_onlyMutualFilter && (_activeTab == ActiveTab.followers || _activeTab == ActiveTab.following)) {
      final mutualSet = _result?.mutual.map((u) => u.username.toLowerCase()).toSet() ?? {};
      filtered = filtered.where((u) => mutualSet.contains(u.username.toLowerCase())).toList();
    }

    // 4. Sorting
    final sorted = List<InstagramUser>.from(filtered);
    switch (_sortOption) {
      case SortOption.dateDesc:
        sorted.sort((a, b) {
          if (a.parsedDate == null && b.parsedDate == null) return 0;
          if (a.parsedDate == null) return 1;
          if (b.parsedDate == null) return -1;
          return b.parsedDate!.compareTo(a.parsedDate!);
        });
        break;
      case SortOption.dateAsc:
        sorted.sort((a, b) {
          if (a.parsedDate == null && b.parsedDate == null) return 0;
          if (a.parsedDate == null) return 1;
          if (b.parsedDate == null) return -1;
          return a.parsedDate!.compareTo(b.parsedDate!);
        });
        break;
      case SortOption.alphabeticalAsc:
        sorted.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
        break;
      case SortOption.alphabeticalDesc:
        sorted.sort((a, b) => b.username.toLowerCase().compareTo(a.username.toLowerCase()));
        break;
    }

    return sorted;
  }

  void _navigateToLostFollowers() {
    if (_result == null) return;
    final comp = _comparison ??
        ComparisonResult(
          lostFollowers: const [],
          unfollowedByMe: _result!.recentlyUnfollowedByMe,
          newFollowers: const [],
          newFollowing: const [],
          hasComparison: false,
        );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LostFollowersScreen(
          comparison: comp,
          currentFollowersCount: _result!.followers.length,
        ),
      ),
    );
  }

  void _navigateToUnfollowedByMe() {
    if (_result == null) return;
    final list = (_comparison != null && _comparison!.unfollowedByMe.isNotEmpty)
        ? _comparison!.unfollowedByMe
        : _result!.recentlyUnfollowedByMe;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnfollowedByMeScreen(
          unfollowedList: list,
          hasComparison: _comparison?.hasComparison ?? false,
          previousExportDate: _comparison?.previousExportDate,
          currentExportDate: _comparison?.currentExportDate ?? _result!.exportDate,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF833AB4),
                      Color(0xFFFD1D1D),
                      Color(0xFFFCB045),
                    ],
                  ),
                ),
                child: const Icon(Icons.person_remove_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                'UnInsta',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Private, Offline-First Instagram Analyzer',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildAboutRow(
                      icon: Icons.verified_outlined,
                      label: 'Software Version',
                      value: 'v1.0.1',
                      theme: theme,
                    ),
                    const Divider(height: 20),
                    _buildAboutRow(
                      icon: Icons.security_outlined,
                      label: 'Privacy Guarantee',
                      value: '100% Offline • Zero Network Tracking',
                      theme: theme,
                    ),
                    const Divider(height: 20),
                    _buildAboutRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Developer',
                      value: 'Mina Android',
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://github.com/mina-android/UnInsta');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.code_rounded, size: 18),
                      label: const Text('GitHub Repo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://portfolio.minaashraf285.workers.dev');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.person_pin_rounded, size: 18),
                      label: const Text('Developer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accentColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF833AB4),
                    Color(0xFFFD1D1D),
                    Color(0xFFFCB045),
                  ],
                ),
              ),
              child: const Icon(Icons.person_remove_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'UnInsta',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About UnInsta & Developer',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showAboutDialog(context),
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: widget.onToggleTheme,
          ),
          if (_result != null) ...[
            IconButton(
              tooltip: 'Import another export file',
              icon: const Icon(Icons.upload_file_rounded),
              onPressed: _pickZipFile,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Options',
              onSelected: (val) {
                if (val == 'clear') _clearStoredData();
                if (val == 'import') _pickZipFile();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Import New ZIP'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Clear Stored Data', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.accentColor),
            const SizedBox(height: 20),
            Text(
              'Loading Instagram export data...',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Restoring followers, following & pending requests',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return _buildUploadPrompt(theme);
    }

    return _buildDashboard(theme, isDark);
  }

  Widget _buildUploadPrompt(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF833AB4),
                      Color(0xFFFD1D1D),
                      Color(0xFFFCB045),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.archive_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Import Instagram Export',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Select your Instagram data export (.zip) to detect non-followers and pending follow requests.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _pickZipFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Select Instagram .zip File', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (File(defaultSamplePath).existsSync()) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _loadZipFromFilePath(defaultSamplePath),
                  icon: const Icon(Icons.bolt_rounded, color: AppTheme.accentColor),
                  label: const Text('Quick Load Downloaded Export'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'How to get your Instagram export:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '1. Open Instagram > Settings > Accounts Center\n'
                        '2. Tap "Your information and permissions"\n'
                        '3. Tap "Download your information"\n'
                        '4. Select "Followers and following" and choose Download to device (.zip).',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, bool isDark) {
    final filteredList = _getFilteredAndSortedList();
    final totalInTab = _getCurrentList().length;

    return Column(
      children: [
        // Account Owner & Session Persistence Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isFromCache ? Icons.cloud_done_rounded : Icons.verified_user_outlined,
                size: 16,
                color: _isFromCache ? Colors.teal : AppTheme.accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _result?.accountOwner != null
                              ? '@${_result!.accountOwner!}'
                              : 'Instagram Export',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        if (_isFromCache) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Cached',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_result?.exportDate != null)
                      Text(
                        'Export date: ${_result!.exportDate!}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _pickZipFile,
                icon: const Icon(Icons.sync_rounded, size: 14),
                label: const Text('New ZIP', style: TextStyle(fontSize: 11.5)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),

        // Comparison Action Banners (Who Unfollowed Me & Recently Unfollowed by Me)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _navigateToLostFollowers,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_remove_rounded, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _comparison?.hasComparison == true
                                ? 'Unfollowed Me (${_comparison!.lostFollowers.length})'
                                : 'Who Unfollowed Me',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _navigateToUnfollowedByMe,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_remove_outlined, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Unfollowed by Me (${(_comparison?.unfollowedByMe.isNotEmpty == true) ? _comparison!.unfollowedByMe.length : _result!.recentlyUnfollowedByMe.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Compact Horizontal Stats Row
        SizedBox(
          height: 74,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              StatSummaryCard(
                title: "Don't Follow",
                count: _result!.notFollowingBack.length,
                icon: Icons.person_remove_rounded,
                accentColor: AppTheme.dangerColor,
                isSelected: _activeTab == ActiveTab.notFollowingBack,
                onTap: () => setState(() => _activeTab = ActiveTab.notFollowingBack),
              ),
              const SizedBox(width: 8),
              StatSummaryCard(
                title: "Pending",
                count: _result!.pendingRequests.length,
                icon: Icons.schedule_send_rounded,
                accentColor: AppTheme.pendingColor,
                isSelected: _activeTab == ActiveTab.pendingRequests,
                onTap: () => setState(() => _activeTab = ActiveTab.pendingRequests),
              ),
              const SizedBox(width: 8),
              StatSummaryCard(
                title: "Fans",
                count: _result!.fans.length,
                icon: Icons.favorite_border_rounded,
                accentColor: Colors.amber.shade700,
                isSelected: _activeTab == ActiveTab.fans,
                onTap: () => setState(() => _activeTab = ActiveTab.fans),
              ),
              const SizedBox(width: 8),
              StatSummaryCard(
                title: "Mutuals",
                count: _result!.mutual.length,
                icon: Icons.people_alt_rounded,
                accentColor: AppTheme.successColor,
                isSelected: _activeTab == ActiveTab.mutual,
                onTap: () => setState(() => _activeTab = ActiveTab.mutual),
              ),
              const SizedBox(width: 8),
              StatSummaryCard(
                title: "Following",
                count: _result!.following.length,
                icon: Icons.person_search_rounded,
                accentColor: Colors.blue.shade600,
                isSelected: _activeTab == ActiveTab.following,
                onTap: () => setState(() => _activeTab = ActiveTab.following),
              ),
              const SizedBox(width: 8),
              StatSummaryCard(
                title: "Followers",
                count: _result!.followers.length,
                icon: Icons.group_outlined,
                accentColor: Colors.teal.shade600,
                isSelected: _activeTab == ActiveTab.followers,
                onTap: () => setState(() => _activeTab = ActiveTab.followers),
              ),
            ],
          ),
        ),

        // Search and Sort Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search in ${_getTabTitle(_activeTab)} ($totalInTab)...',
                  leading: const Icon(Icons.search, size: 18),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Sort list',
                initialValue: _sortOption,
                onSelected: (order) => setState(() => _sortOption = order),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: SortOption.dateDesc,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Date (Newest First)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: SortOption.dateAsc,
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Date (Oldest First)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: SortOption.alphabeticalAsc,
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Alphabetical (A-Z)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: SortOption.alphabeticalDesc,
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Alphabetical (Z-A)'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter Chips Row (Date Ranges & Mutual Status)
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip(
                label: 'All Time',
                isSelected: _dateFilter == DateFilter.all,
                onTap: () => setState(() => _dateFilter = DateFilter.all),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: '< 30 Days',
                isSelected: _dateFilter == DateFilter.last30Days,
                onTap: () => setState(() => _dateFilter = DateFilter.last30Days),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: '< 6 Months',
                isSelected: _dateFilter == DateFilter.last6Months,
                onTap: () => setState(() => _dateFilter = DateFilter.last6Months),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: '< 1 Year',
                isSelected: _dateFilter == DateFilter.last1Year,
                onTap: () => setState(() => _dateFilter = DateFilter.last1Year),
              ),
              const SizedBox(width: 6),
              _buildFilterChip(
                label: '> 1 Year',
                isSelected: _dateFilter == DateFilter.olderThan1Year,
                onTap: () => setState(() => _dateFilter = DateFilter.olderThan1Year),
              ),
              if (_activeTab == ActiveTab.followers || _activeTab == ActiveTab.following) ...[
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'Mutual Only',
                  isSelected: _onlyMutualFilter,
                  onTap: () => setState(() => _onlyMutualFilter = !_onlyMutualFilter),
                  icon: Icons.people_outline_rounded,
                ),
              ],
            ],
          ),
        ),

        // Active Tab Title and Count Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text(
                _getTabTitle(_activeTab),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${filteredList.length}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _getSortDescription(_sortOption),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 2),

        // Users List
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isEmpty && _dateFilter == DateFilter.all
                            ? 'No accounts in this list'
                            : 'No matching accounts found',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24, top: 2),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final user = filteredList[index];
                    return UserCard(
                      key: ValueKey('${_activeTab.name}_${user.username}'),
                      user: user,
                      index: index + 1,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ActionChip(
      onPressed: onTap,
      avatar: icon != null
          ? Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            )
          : null,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      backgroundColor: isSelected
          ? AppTheme.accentColor
          : isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected
            ? AppTheme.accentColor
            : isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _getSortDescription(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
        return 'Sorted: Newest';
      case SortOption.dateAsc:
        return 'Sorted: Oldest';
      case SortOption.alphabeticalAsc:
        return 'Sorted: A-Z';
      case SortOption.alphabeticalDesc:
        return 'Sorted: Z-A';
    }
  }
}
