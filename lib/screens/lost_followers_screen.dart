import 'package:flutter/material.dart';
import '../models/instagram_models.dart';
import '../widgets/user_card.dart';

enum DateSortOrder {
  dateDesc,
  dateAsc,
  alphabeticalAsc,
  alphabeticalDesc,
}

class LostFollowersScreen extends StatefulWidget {
  final ComparisonResult comparison;
  final int currentFollowersCount;

  const LostFollowersScreen({
    super.key,
    required this.comparison,
    required this.currentFollowersCount,
  });

  @override
  State<LostFollowersScreen> createState() => _LostFollowersScreenState();
}

class _LostFollowersScreenState extends State<LostFollowersScreen> {
  String _searchQuery = '';
  DateSortOrder _sortOrder = DateSortOrder.alphabeticalAsc;
  final TextEditingController _searchController = TextEditingController();

  List<InstagramUser> _getFilteredAndSorted() {
    final list = widget.comparison.lostFollowers;
    var filtered = list;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        return u.username.toLowerCase().contains(q) ||
            (u.displayName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    final sorted = List<InstagramUser>.from(filtered);
    switch (_sortOrder) {
      case DateSortOrder.dateDesc:
        sorted.sort((a, b) {
          if (a.parsedDate == null && b.parsedDate == null) return 0;
          if (a.parsedDate == null) return 1;
          if (b.parsedDate == null) return -1;
          return b.parsedDate!.compareTo(a.parsedDate!);
        });
        break;
      case DateSortOrder.dateAsc:
        sorted.sort((a, b) {
          if (a.parsedDate == null && b.parsedDate == null) return 0;
          if (a.parsedDate == null) return 1;
          if (b.parsedDate == null) return -1;
          return a.parsedDate!.compareTo(b.parsedDate!);
        });
        break;
      case DateSortOrder.alphabeticalAsc:
        sorted.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
        break;
      case DateSortOrder.alphabeticalDesc:
        sorted.sort((a, b) => b.username.toLowerCase().compareTo(a.username.toLowerCase()));
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final list = _getFilteredAndSorted();
    final hasComparison = widget.comparison.hasComparison;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Unfollowed Me'),
        actions: [
          PopupMenuButton<DateSortOrder>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort list',
            initialValue: _sortOrder,
            onSelected: (val) => setState(() => _sortOrder = val),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DateSortOrder.dateDesc,
                child: Text('Date (Newest First)'),
              ),
              const PopupMenuItem(
                value: DateSortOrder.dateAsc,
                child: Text('Date (Oldest First)'),
              ),
              const PopupMenuItem(
                value: DateSortOrder.alphabeticalAsc,
                child: Text('Alphabetical (A-Z)'),
              ),
              const PopupMenuItem(
                value: DateSortOrder.alphabeticalDesc,
                child: Text('Alphabetical (Z-A)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Informational Comparison Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasComparison
                            ? 'Comparing with Previous Export'
                            : 'Baseline Followers Cached',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasComparison
                            ? '${widget.comparison.previousExportDate ?? "Previous"} → ${widget.comparison.currentExportDate ?? "Latest"}'
                            : '${widget.currentFollowersCount} followers saved. Upload a newer export later to see who unfollowed you.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (hasComparison) ...[
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search lost followers (${widget.comparison.lostFollowers.length})...',
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
          ],

          const SizedBox(height: 6),

          // List or Empty State
          Expanded(
            child: !hasComparison
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.history_toggle_off_rounded,
                              size: 48,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'First Export Cached!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'UnInsta has saved your current followers list as a snapshot.\n\nWhenever you download and upload a new Instagram export in the future, UnInsta will compare them and list the exact profiles who unfollowed you!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 52, color: Colors.green),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No one has unfollowed you since your last export!'
                                  : 'No accounts match "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20, top: 4),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          return UserCard(
                            key: ValueKey('lost_${list[index].username}'),
                            user: list[index],
                            index: index + 1,
                            badgeText: 'Unfollowed You',
                            badgeColor: Colors.red,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
