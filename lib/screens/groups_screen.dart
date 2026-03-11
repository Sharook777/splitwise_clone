import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../models/group_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';

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
  String? _currentUserEmail;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    if (_currentUserEmail != null) {
      final results = await DatabaseService.searchGroups(
        query,
        _currentUserEmail!,
      );
      setState(() => _searchResults = results);
    }
  }

  void _showCreateGroupDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
                onSaved: (value) => name = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context);

                if (_currentUserEmail != null) {
                  await DatabaseService.createGroup(name, _currentUserEmail!);
                  _loadGroups();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name group created')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        // Custom Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: _isSearching
              ? _buildSearchHeader(themeColor)
              : _buildDefaultHeader(themeColor),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_isSearching ? _searchResults : _groups).isEmpty
              ? _buildEmptyState(themeColor)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
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
                icon: HugeIconsStrokeRounded
                    .addSquare, // Changed to userGroup for groups
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
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _showCreateGroupDialog,
          icon: HugeIcon(
            icon: HugeIconsStrokeRounded.addSquare,
            color: Colors.grey[800]!,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTile(Group group, Color themeColor) {
    final initial = group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: themeColor.withOpacity(0.1),
          child: Text(
            initial,
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Group ID: ${group.id}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Future: Navigate to group details/expenses
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
              color: themeColor.withOpacity(0.3),
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
    );
  }
}
