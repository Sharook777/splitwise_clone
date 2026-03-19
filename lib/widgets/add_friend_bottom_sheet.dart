import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';

class AddFriendBottomSheet extends StatefulWidget {
  final VoidCallback onFriendAdded;

  const AddFriendBottomSheet({super.key, required this.onFriendAdded});

  @override
  State<AddFriendBottomSheet> createState() => _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends State<AddFriendBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  String _name = '';
  String _email = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onNameFocusChange);
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChange);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onNameFocusChange() {
    if (mounted && !_nameFocusNode.hasFocus) {
      _nameKey.currentState?.validate();
    }
  }

  void _onEmailFocusChange() {
    if (mounted && !_emailFocusNode.hasFocus) {
      _emailKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFECECEC),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 24 + bottomInset,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Friend',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: HugeIcon(
                            icon: HugeIconsStrokeRounded.cancel01,
                            color: Colors.grey[600]!,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a new friend to start splitting expenses!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 15),
                    Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _buildTextField(
                            key: _nameKey,
                            label: 'Name',
                            hint: 'Enter friend\'s name',
                            icon: HugeIconsStrokeRounded.user,
                            focusNode: _nameFocusNode,
                            onSaved: (value) => _name = value!,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter a name'
                                : null,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            key: _emailKey,
                            label: 'Email',
                            hint: 'Enter friend\'s email',
                            icon: HugeIconsStrokeRounded.mail01,
                            focusNode: _emailFocusNode,
                            onSaved: (value) => _email = value!,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Add Friend',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required dynamic icon,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    Key? key,
    FocusNode? focusNode,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final themeColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        TextFormField(
          key: key,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          onSaved: onSaved,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            prefixIcon: SizedBox(
              width: 45,
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 20.0,
                  strokeWidth: 2,
                  color: themeColor,
                ),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(color: themeColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    final themeColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIconsStrokeRounded.alertDiamond,
                  color: themeColor,
                  size: 60,
                  strokeWidth: 2,
                ),

                const SizedBox(height: 20),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "OK",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final messenger = ScaffoldMessenger.of(context);

      try {
        final currentUserEmail = await SessionService.getUserEmail();
        if (currentUserEmail != null) {
          // 1. Self-Check
          if (_email.toLowerCase() == currentUserEmail.toLowerCase()) {
            _showErrorDialog('You cannot add yourself as a friend');
            setState(() => _isLoading = false);
            return;
          }

          // 2. Duplicate Check
          final existingFriends = await DatabaseService.getFriends(
            currentUserEmail,
          );
          final isAlreadyFriend = existingFriends.any(
            (f) => f.email.toLowerCase() == _email.toLowerCase(),
          );

          if (isAlreadyFriend) {
            _showErrorDialog('$_email is already your friend');
            setState(() => _isLoading = false);
            return;
          }

          // 3. Add Friend (and User if not exists)
          final existingUser = await DatabaseService.getUserByEmail(_email);
          if (existingUser == null) {
            await DatabaseService.insertUser(User(name: _name, email: _email));
          }
          await DatabaseService.addFriend(currentUserEmail, _email);

          if (mounted) {
            Navigator.pop(context);
            widget.onFriendAdded();
            messenger.showSnackBar(
              SnackBar(
                content: Text('$_name added as friend'),
                backgroundColor: Colors.green[600],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        _showErrorDialog('Failed to add friend');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
