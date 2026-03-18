import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../widgets/add_friend_bottom_sheet.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/split_engine.dart';
import 'friend_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<User> _friends = [];
  Map<String, Map<String, double>> _friendActivity = {};
  List<User> _searchResults = [];
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
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    _currentUserEmail = await SessionService.getUserEmail();
    if (_currentUserEmail != null) {
      final friends = await DatabaseService.getFriends(_currentUserEmail!);
      final activity = await DatabaseService.getFriendsActivity(
        _currentUserEmail!,
      );
      setState(() {
        _friends = friends;
        _friendActivity = activity;
        _isLoading = false;
      });
      final symbol = await SessionService.getCurrencySymbol();
      if (mounted) {
        setState(() {
          _currencySymbol = symbol;
        });
      }
    } else {
      setState(() => _isLoading = false);
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
        final results = await DatabaseService.searchUsers(
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

  void _showAddFriendBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFriendBottomSheet(onFriendAdded: _loadFriends),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFECECEC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFFECECEC),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: _isSearching
                    ? _buildSearchHeader(themeColor)
                    : _buildDefaultHeader(themeColor),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isSearchingData
                    ? _buildSkeletonList()
                    : (_isSearching ? _searchResults : _friends).isEmpty
                    ? _buildEmptyState(themeColor)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _isSearching
                            ? _searchResults.length
                            : _friends.length,
                        itemBuilder: (context, index) {
                          final user = _isSearching
                              ? _searchResults[index]
                              : _friends[index];
                          return _buildUserTile(
                            user,
                            themeColor,
                            isSearchResult: _isSearching,
                          );
                        },
                      ),
              ),
            ],
          ),
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
                  shape: BoxShape.circle,
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
              onPressed: _showAddFriendBottomSheet,
              icon: HugeIcon(
                icon: HugeIconsStrokeRounded.addSquare,
                color: Colors.grey[800]!,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchHeader(Color themeColor) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Search friends...',
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
        ),
      ],
    );
  }

  Widget _buildUserTile(
    User user,
    Color themeColor, {
    bool isSearchResult = false,
  }) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    // Check if user is already a friend if it's a search result
    final isAlreadyFriend =
        !isSearchResult ||
        _friends.any((f) => f.email.toLowerCase() == user.email.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Hero(
          tag: 'friend-avatar-${user.email}',
          child: CircleAvatar(
            radius: 24,
            backgroundColor: themeColor.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_friendActivity.containsKey(user.email.toLowerCase()))
              Builder(
                builder: (context) {
                  final activity = _friendActivity[user.email.toLowerCase()]!;
                  final toCollect = activity['toCollect'] ?? 0.0;
                  final toPay = activity['toPay'] ?? 0.0;

                  if (toCollect < 0.01 && toPay < 0.01) {
                    return Text(
                      'Settled',
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (toCollect >= 0.01)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_currencySymbol${formatAmount(toCollect)}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            HugeIcon(
                              icon: HugeIconsStrokeRounded.circleArrowLeft02,
                              size: 14,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      if (toPay >= 0.01)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_currencySymbol${formatAmount(toPay)}',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            HugeIcon(
                              icon: HugeIconsStrokeRounded.circleArrowRight02,
                              size: 14,
                              color: Colors.red,
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(width: 10),
            HugeIcon(
              icon: HugeIconsStrokeRounded.arrowRight01,
              size: 16,
              color: Colors.grey[400]!,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendDetailScreen(friend: user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color themeColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
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
              _isSearching ? 'No friends found' : 'No friends added yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Try searching for a different name or email.'
                  : 'Add friends to start splitting expenses!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
