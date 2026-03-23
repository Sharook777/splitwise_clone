import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../utils/split_engine.dart';
import '../models/group_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../widgets/add_group_bottom_sheet.dart';
import '../widgets/shimmer_loading.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> _groups = [];
  List<Group> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSearchingData = false;
  String? _currentUserEmail;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      _currentUserEmail = await SessionService.getUserEmail();
      if (_currentUserEmail != null) {
        final groups = await DatabaseService.getGroupsForUser(
          _currentUserEmail!,
        );
        setState(() {
          _groups = groups;
        });
        final symbol = await SessionService.getCurrencySymbol();
        if (mounted) {
          setState(() {
            _currencySymbol = symbol;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load groups')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _performSearch(String query) {
    _searchTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingData = false;
      });
      return;
    }

    setState(() => _isSearchingData = true);

    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_currentUserEmail != null) {
        final results = await DatabaseService.searchGroups(
          query,
          _currentUserEmail!,
        );
        setState(() {
          _searchResults = results;
          _isSearchingData = false;
        });
      }
    });
  }

  void _showCreateGroupDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGroupBottomSheet(onGroupAdded: _loadGroups),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFECECEC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFECECEC),
        body: Column(
          children: [
            const SizedBox(height: 50),
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _isSearching
                  ? _buildSearchField(themeColor)
                  : _buildDefaultHeader(themeColor),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isSearchingData
                  ? _buildSkeletonList()
                  : (_isSearching ? _searchResults : _groups).isEmpty
                  ? _buildEmptyState(themeColor)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 300),
                      itemCount: _isSearching
                          ? _searchResults.length
                          : _groups.length,
                      itemBuilder: (context, index) {
                        final group = _isSearching
                            ? _searchResults[index]
                            : _groups[index];
                        return _buildGroupTile(group, themeColor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultHeader(Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: HugeIcon(
                icon: HugeIconsStrokeRounded.search01,
                color: Colors.grey[800]!,
                size: 24,
              ),
            ),
            IconButton(
              onPressed: _showCreateGroupDialog,
              icon: HugeIcon(
                icon: HugeIconsStrokeRounded.addSquare,
                color: Colors.grey[800]!,
                size: 24,
              ),
              tooltip: 'Create Group',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(Color themeColor) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search groups...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: SizedBox(
            width: 35,
            height: 35,
            child: Center(
              child: HugeIcon(
                icon: HugeIconsStrokeRounded.search01,
                size: 24.0,
                strokeWidth: 2,
                color: themeColor,
              ),
            ),
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              if (_searchController.text.isNotEmpty) {
                _searchController.clear();
                _performSearch('');
              } else {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults = [];
                });
              }
            },
            child: SizedBox(
              width: 35,
              height: 35,
              child: Center(
                child: HugeIcon(
                  icon: HugeIconsStrokeRounded.cancel01,
                  size: 24.0,
                  strokeWidth: 2,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: themeColor, width: 2),
          ),
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildGroupTile(Group group, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Hero(
          tag: 'group-icon-${group.id}',
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: HugeIcon(
              icon: HugeIconsStrokeRounded.bitcoinBag,
              color: themeColor,
              size: 20,
              strokeWidth: 2,
            ),
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            HugeIcon(
              icon: HugeIconsStrokeRounded.userGroup,
              size: 15,
              color: themeColor,
            ),
            SizedBox(width: 5),
            Text(
              '${group.memberNames.length}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            SizedBox(width: 10),
            Text('•', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            SizedBox(width: 10),
            HugeIcon(
              icon: HugeIconsStrokeRounded.dollarCircle,
              size: 15,
              color: themeColor,
            ),
            SizedBox(width: 5),
            Text(
              '$_currencySymbol${formatAmount(group.totalSpend)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        trailing: HugeIcon(
          icon: HugeIconsStrokeRounded.arrowRight01,
          size: 16,
          color: Colors.grey[400]!,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(group: group),
            ),
          ).then((_) => _loadGroups());
        },
      ),
    );
  }

  Widget _buildEmptyState(Color themeColor) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: _isSearching
                    ? HugeIconsStrokeRounded.search01
                    : HugeIconsStrokeRounded.userGroup,
                size: 80,
                color: themeColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 20),
              Text(
                _isSearching ? 'No groups found' : 'No groups yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSearching
                    ? 'Try searching for a different group name.'
                    : 'Create a group to start splitting expenses with multiple people!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
