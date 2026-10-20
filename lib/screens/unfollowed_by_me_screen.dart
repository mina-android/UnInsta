import 'package:flutter/material.dart';
import '../models/instagram_models.dart';
import '../widgets/user_card.dart';
import 'lost_followers_screen.dart';

class UnfollowedByMeScreen extends StatefulWidget {
  final List<InstagramUser> unfollowedList;
  final bool hasComparison;
  final String? previousExportDate;
  final String? currentExportDate;

  const UnfollowedByMeScreen({
    super.key,
    required this.unfollowedList,
    required this.hasComparison,
    this.previousExportDate,
    this.currentExportDate,
  });

  @override
  State<UnfollowedByMeScreen> createState() => _UnfollowedByMeScreenState();
}

class _UnfollowedByMeScreenState extends State<UnfollowedByMeScreen> {
  String _searchQuery = '';
  DateSortOrder _sortOrder = DateSortOrder.dateDesc;
  final TextEditingController _searchController = TextEditingController();

  List<InstagramUser> _getFilteredAndSorted() {
    final list = widget.unfollowedList;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Unfollowed by Me'),
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
          // Header Card
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
                    color: Colors.orange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_remove_outlined, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Unfollowed: ${widget.unfollowedList.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.hasComparison
                            ? 'From export records + comparison with previous export.'
                            : 'Profiles you recently stopped following from your export.',
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search unfollowed profiles (${widget.unfollowedList.length})...',
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

          const SizedBox(height: 6),

          // List or Empty
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No recently unfollowed profiles recorded.'
                              : 'No accounts match "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20, top: 4),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return UserCard(
                        key: ValueKey('unfollowed_me_${list[index].username}'),
                        user: list[index],
                        index: index + 1,
                        badgeText: 'Unfollowed by You',
                        badgeColor: Colors.orange,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
