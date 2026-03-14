import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;
  final List<User> members;

  const AddExpenseScreen({
    super.key,
    required this.group,
    required this.members,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _currentUserEmail;
  User? _paidBy;
  String _splitType = 'Equally'; // Equally, Uniquely, Percentage, Shares

  // email -> value (depending on _splitType)
  Map<String, double> _splitValues = {};
  List<User> _selectedSplitMembers = [];
  List<User> _sortedMembers = [];

  @override
  void initState() {
    super.initState();
    _selectedSplitMembers = [];
    _sortedMembers = List.from(widget.members);
    _loadCurrentUser();

    _amountController.addListener(_onAmountChanged);

    // Initialize split values
    for (var m in widget.members) {
      if (_splitType == 'Shares') {
        _splitValues[m.email] = 1.0;
      } else {
        _splitValues[m.email] = 0.0;
      }
    }
  }

  void _onAmountChanged() {
    if (_splitType == 'Equally') {
      setState(() {}); // Trigger rebuild to update split amounts
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserEmail = await SessionService.getUserEmail();
    if (_currentUserEmail != null) {
      setState(() {
        _paidBy = widget.members.firstWhere(
          (m) => m.email.toLowerCase() == _currentUserEmail?.toLowerCase(),
          orElse: () => widget.members.first,
        );

        // Reorder members to put "Me" first
        _sortedMembers.sort((a, b) {
          bool isAMe =
              a.email.toLowerCase() == _currentUserEmail?.toLowerCase();
          bool isBMe =
              b.email.toLowerCase() == _currentUserEmail?.toLowerCase();
          if (isAMe) return -1;
          if (isBMe) return 1;
          return 0;
        });
      });
    }
  }

  void _onSave() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a description');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showErrorSnackBar('Please enter an amount');
      return;
    }

    double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      _showErrorSnackBar('Please enter a valid amount greater than 0');
      return;
    }

    if (_paidBy == null) {
      _showErrorSnackBar('Please select who paid');
      return;
    }

    if (_selectedSplitMembers.isEmpty) {
      _showErrorSnackBar('Please select at least one person to split with');
      return;
    }

    // Split logic validation
    if (_splitType == 'Uniquely (Exact)') {
      double sum = _selectedSplitMembers.fold(
        0,
        (sum, member) => sum + (_splitValues[member.email] ?? 0),
      );
      if ((sum - totalAmount).abs() > 0.01) {
        String symbol = '\$';
        if (widget.group.currency != null &&
            widget.group.currency!.isNotEmpty) {
          symbol = widget.group.currency!.split(' ').first;
        }
        _showErrorSnackBar(
          'Sum of amounts ($symbol${sum.toStringAsFixed(2)}) must equal total ($symbol${totalAmount.toStringAsFixed(2)})',
        );
        return;
      }
    } else if (_splitType == 'Percentage') {
      double sum = _selectedSplitMembers.fold(
        0,
        (sum, member) => sum + (_splitValues[member.email] ?? 0),
      );
      if ((sum - 100).abs() > 0.01) {
        _showErrorSnackBar(
          'Sum of percentages (${sum.toStringAsFixed(1)}%) must equal 100%',
        );
        return;
      }
    } else if (_splitType == 'Shares') {
      double sum = _selectedSplitMembers.fold(
        0,
        (sum, member) => sum + (_splitValues[member.email] ?? 0),
      );
      if (sum <= 0) {
        _showErrorSnackBar('Total shares must be greater than 0');
        return;
      }
    }

    // TODO: Actually save the expense to DatabaseService
    Navigator.pop(context);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFECECEC),
        body: SafeArea(
          child: Column(
            children: [
              // Fixed Top Section (Header + Amount/Description)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderIcon(
                          HugeIconsStrokeRounded.arrowLeft01,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Add Expense',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        _buildHeaderSaveButton(
                          HugeIconsStrokeRounded.checkmarkCircle02,
                          onTap: _onSave,
                          iconColor: themeColor,
                        ),
                      ],
                    ),
                  ),

                  // Amount & Description Box (Fixed)
                ],
              ),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 65),
                              child: Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d{0,6}(\.?\d{0,2})'),
                                ),
                              ],
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Colors.grey[200],
                                  fontSize: 38,
                                  height: 1.1,
                                ),
                                filled: true,
                                fillColor: themeColor.withOpacity(0.01),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 0,
                                    right: 12,
                                  ),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: themeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (widget.group.currency != null &&
                                                widget
                                                    .group
                                                    .currency!
                                                    .isNotEmpty)
                                            ? widget.group.currency!
                                                  .split(' ')
                                                  .first
                                            : '\$',
                                        style: TextStyle(
                                          color: themeColor,
                                          fontSize: 24,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              margin: const EdgeInsets.only(left: 65),
                              child: Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: HugeIcon(
                                    icon: HugeIconsStrokeRounded.note01,
                                    color: themeColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _descriptionController,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter a description',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Date Action
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          children: [
                            _buildActionButton(
                              themeColor: themeColor,
                              icon: HugeIconsStrokeRounded.calendar03,
                              label: DateFormat(
                                'dd MMM, yyyy',
                              ).format(_selectedDate),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: themeColor,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Paid By & Split Section
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildSelectionTile(
                          title: 'Paid by',
                          value:
                              _paidBy?.email.toLowerCase() ==
                                  _currentUserEmail?.toLowerCase()
                              ? 'Me'
                              : (_paidBy?.name ?? 'Select'),
                          icon: HugeIconsStrokeRounded.userCircle,
                          onTap: _showPaidByDialog,
                          themeColor: themeColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildSelectionTile(
                          title: 'Split',
                          value: _splitType,
                          icon: HugeIconsStrokeRounded.divideSign,
                          onTap: _showSplitTypeDialog,
                          themeColor: themeColor,
                          isSecondary: true,
                        ),
                      ),

                      // Split List
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SPLIT WITH',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 15),
                            ..._sortedMembers.map((member) {
                              bool isMe =
                                  member.email.toLowerCase() ==
                                  _currentUserEmail?.toLowerCase();
                              bool isSelected = _selectedSplitMembers.any(
                                (m) => m.email == member.email,
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? themeColor.withOpacity(0.05)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? themeColor
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedSplitMembers.removeWhere(
                                              (m) => m.email == member.email,
                                            );
                                          } else {
                                            _selectedSplitMembers.add(member);
                                          }
                                        });
                                      },
                                      child: HugeIcon(
                                        icon: isSelected
                                            ? HugeIconsStrokeRounded
                                                  .checkmarkCircle02
                                            : HugeIconsStrokeRounded.circle,
                                        color: isSelected
                                            ? themeColor
                                            : Colors.grey[300]!,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isMe ? 'Me' : member.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isSelected
                                                  ? themeColor
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            member.email,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 12,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected && _splitType == 'Equally')
                                      Text(
                                        '${(widget.group.currency != null && widget.group.currency!.isNotEmpty) ? widget.group.currency!.split(' ').first : '\$'} ${_calculateSplitAmount(member.email)}',
                                        style: TextStyle(
                                          color: themeColor.withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (_splitType != 'Equally' && isSelected)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F5F5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(
                                                  RegExp(
                                                    r'^\d{0,6}(\.?\d{0,2})',
                                                  ),
                                                ),
                                              ],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                height: 1,
                                                color: themeColor,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText:
                                                    _splitType == 'Percentage'
                                                    ? '0%'
                                                    : '0',
                                                suffixText:
                                                    _splitType == 'Percentage'
                                                    ? '%'
                                                    : null,
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                  height: 1,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 8,
                                                    ),
                                                suffixStyle: TextStyle(
                                                  color: themeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                border: InputBorder.none,
                                              ),
                                              onChanged: (val) {
                                                double d =
                                                    double.tryParse(val) ?? 0.0;
                                                setState(
                                                  () =>
                                                      _splitValues[member
                                                              .email] =
                                                          d,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(widget.group.currency != null && widget.group.currency!.isNotEmpty) ? widget.group.currency!.split(' ').first : '\$'} ${_calculateSplitAmount(member.email)}',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 100),
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
      ),
    );
  }

  String _calculateSplitAmount(String email) {
    if (!_selectedSplitMembers.any((m) => m.email == email)) return '0.00';
    double total = double.tryParse(_amountController.text) ?? 0.0;
    if (total <= 0 || _selectedSplitMembers.isEmpty) return '0.00';

    if (_splitType == 'Equally') {
      // Calculate basic per-person amount
      double perPerson =
          (total / _selectedSplitMembers.length * 100).floorToDouble() / 100.0;

      // Calculate total distributed so far
      double distributed = perPerson * _selectedSplitMembers.length;

      // Calculate remainder in cents
      double remainder = (total - distributed);

      // We'll give the remainder to the person who appears first in the sorted list
      final firstSelectedMember = _sortedMembers.firstWhere(
        (m) => _selectedSplitMembers.any((sm) => sm.email == m.email),
      );
      if (email == firstSelectedMember.email) {
        return (perPerson + remainder).toStringAsFixed(2);
      }
      return perPerson.toStringAsFixed(2);
    } else if (_splitType == 'Percentage') {
      double percentage = _splitValues[email] ?? 0.0;
      return (total * percentage / 100).toStringAsFixed(2);
    } else if (_splitType == 'Shares') {
      double totalShares = _selectedSplitMembers.fold(
        0,
        (sum, m) => sum + (_splitValues[m.email] ?? 0),
      );
      if (totalShares <= 0) return '0.00';
      double userShares = _splitValues[email] ?? 0.0;
      return (total * userShares / totalShares).toStringAsFixed(2);
    } else if (_splitType == 'Uniquely (Exact)') {
      return (_splitValues[email] ?? 0.0).toStringAsFixed(2);
    }

    return '0.00';
  }

  Widget _buildActionButton({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    required dynamic themeColor,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: HugeIcon(icon: icon, color: themeColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String value,
    required dynamic icon,
    required VoidCallback onTap,
    required Color themeColor,
    bool isSecondary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, size: 20, color: themeColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  void _showPaidByDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Who paid?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.members.length,
                  itemBuilder: (context, index) {
                    final member = widget.members[index];
                    bool isMe =
                        member.email.toLowerCase() ==
                        _currentUserEmail?.toLowerCase();
                    bool isSelected = _paidBy?.email == member.email;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        radius: 12,
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        isMe ? 'Me' : member.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                      onTap: () {
                        setState(() => _paidBy = member);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSplitTypeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How should we split this?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSplitTypeOption('Equally', 'Divide the cost among members'),
              _buildSplitTypeOption(
                'Uniquely (Exact)',
                'Enter exact amount per member',
              ),
              _buildSplitTypeOption(
                'Percentage',
                'Split by percentage of total',
              ),
              _buildSplitTypeOption('Shares', 'Split by multiple shares'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitTypeOption(String type, String sub) {
    bool isSelected = _splitType == type;
    return ListTile(
      title: Text(
        type,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        setState(() {
          _splitType = type;
          // Reset split values based on type
          for (var m in widget.members) {
            _splitValues[m.email] = (type == 'Shares' ? 1.0 : 0.0);
          }
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildHeaderIcon(
    dynamic icon, {
    VoidCallback? onTap,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: HugeIcon(icon: icon, color: iconColor, size: 24, strokeWidth: 2),
      ),
    );
  }

  Widget _buildHeaderSaveButton(
    dynamic icon, {
    VoidCallback? onTap,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HugeIcon(icon: icon, color: Colors.white, size: 24, strokeWidth: 2),
            const SizedBox(width: 10),
            Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
