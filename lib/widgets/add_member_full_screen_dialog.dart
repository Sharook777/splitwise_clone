import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';

class AddMemberFullScreenDialog extends StatefulWidget {
  final Color themeColor;
  final Group group;
  final List<User> existingMembers;
  final VoidCallback onMembersAdded;

  const AddMemberFullScreenDialog({
    super.key,
    required this.themeColor,
    required this.group,
    required this.existingMembers,
    required this.onMembersAdded,
  });

  @override
  State<AddMemberFullScreenDialog> createState() =>
      _AddMemberFullScreenDialogState();
}

class _AddMemberFullScreenDialogState
    extends State<AddMemberFullScreenDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _allFriends = [];
  List<User> _displayedFriends = [];
  final Set<String> _selectedEmails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final currentUserEmail = await SessionService.getUserEmail();
    if (currentUserEmail != null) {
      final friends = await DatabaseService.getFriends(currentUserEmail);
      // Filter out those who are already in the group
      final existingEmails = widget.existingMembers
          .map((m) => m.email.toLowerCase())
          .toSet();
      final availableFriends = friends
          .where((f) => !existingEmails.contains(f.email.toLowerCase()))
          .toList();

      setState(() {
        _allFriends = availableFriends;
        _displayedFriends = availableFriends;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterFriends(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _displayedFriends = _allFriends.where((f) {
        return f.name.toLowerCase().contains(lowerQuery) ||
            f.email.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedEmails.isEmpty || widget.group.id == null) return;

    for (final email in _selectedEmails) {
      await DatabaseService.addMemberToGroup(widget.group.id!, email);
    }
    widget.onMembersAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFECECEC),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Members',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterFriends,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: SizedBox(
                    width: 35,
                    height: 35,
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIconsStrokeRounded.search01,
                        color: Colors.grey[500]!,
                        size: 20,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.transparent, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Friends List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allFriends.isEmpty
                  ? _buildEmptyState()
                  : _displayedFriends.isEmpty
                  ? Center(
                      child: Text(
                        'No matching friends found',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _displayedFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _displayedFriends[index];
                        final isSelected = _selectedEmails.contains(
                          friend.email,
                        );

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedEmails.remove(friend.email);
                              } else {
                                _selectedEmails.add(friend.email);
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? widget.themeColor
                                    : Colors.grey[100]!,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  friend.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  friend.email,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedEmails.isEmpty
                          ? null
                          : _addSelectedMembers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HugeIcon(
          icon: HugeIconsStrokeRounded.userGroup,
          size: 60,
          color: Colors.grey[300]!,
        ),
        const SizedBox(height: 16),
        Text(
          'No friends available to add',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'All your friends are already in this group\nor you need to add more friends first.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }
}
