import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../utils/debt_engine.dart';
import '../utils/split_engine.dart';

class MemberDetailScreen extends StatefulWidget {
  final Group group;
  final User member;
  final List<Expense> allExpenses;
  final List<ExpenseSplit> allSplits;
  final List<User> allMembers;

  const MemberDetailScreen({
    super.key,
    required this.group,
    required this.member,
    required this.allExpenses,
    required this.allSplits,
    required this.allMembers,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late List<Expense> _paidExpenses;
  late List<Expense> _borrowedExpenses;
  late MemberBalance _balance;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _computeData();
  }

  Future<void> _loadSession() async {
    final email = await SessionService.getUserEmail();
    if (mounted) {
      setState(() {
        _currentUserEmail = email;
      });
    }
  }

  void _computeData() {
    final email = widget.member.email.toLowerCase();

    // Expenses paid by this member
    _paidExpenses = widget.allExpenses
        .where((e) => e.paidByEmail.toLowerCase() == email)
        .toList();

    // Expenses borrowed by this member (where they are in the splits)
    final borrowedExpenseIds = widget.allSplits
        .where((s) => s.userEmail.toLowerCase() == email)
        .map((s) => s.expenseId)
        .toSet();

    _borrowedExpenses = widget.allExpenses
        .where((e) => borrowedExpenseIds.contains(e.id))
        .toList();

    // Balance
    final balances = computeMemberBalances(
      widget.allExpenses,
      widget.allSplits,
    );
    _balance = balances[email] ?? MemberBalance(email: email);
  }

  String _getCurrencySymbol() {
    if (widget.group.currency != null && widget.group.currency!.isNotEmpty) {
      return widget.group.currency!.split(' ').first;
    }
    return '\$';
  }

  bool get _isCurrentUser =>
      _currentUserEmail?.toLowerCase() == widget.member.email.toLowerCase();

  String get _displayName => _isCurrentUser ? 'You' : widget.member.name;

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final symbol = _getCurrencySymbol();
    final balance = _balance.balance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFECECEC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFECECEC),
        body: Column(
          children: [
            // Custom themed header
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 10),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            widget.member.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.member.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (balance.abs() < 0.01)
                        Text(
                          'All settled',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          (balance >= 0 ? 'Gets back' : 'Owes'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (balance.abs() > 0.01) ...[
                        Text(
                          '$symbol ${formatAmount(balance.abs())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () => _showSettleUpDialog(themeColor),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Settle Up',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const HugeIcon(
                        icon: HugeIconsStrokeRounded.arrowLeft01,
                        color: Colors.black,
                        size: 24,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: Visibility(
                    visible:
                        widget.member.id != widget.group.createdBy &&
                        !_isCurrentUser,
                    child: GestureDetector(
                      onTap: () => _showRemoveMemberDialog(themeColor),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const HugeIcon(
                          icon: HugeIconsStrokeRounded.userRemove01,
                          color: Colors.redAccent,
                          size: 24,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                children: [
                  _buildSectionTitle('Payments $_displayName made'),
                  if (_paidExpenses.isEmpty)
                    _buildEmptyState('No payments made yet')
                  else
                    _buildExpenseList(
                      _paidExpenses,
                      themeColor,
                      symbol,
                      isPaid: true,
                    ),

                  const SizedBox(height: 32),

                  _buildSectionTitle('Expenses $_displayName borrowed'),
                  if (_borrowedExpenses.isEmpty)
                    _buildEmptyState('No borrowed expenses ($symbol 0)')
                  else
                    _buildExpenseList(
                      _borrowedExpenses,
                      themeColor,
                      symbol,
                      isPaid: false,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList(
    List<Expense> expenses,
    Color themeColor,
    String symbol, {
    required bool isPaid,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(expenses.length, (index) {
          final expense = expenses[index];
          final dt = DateFormat('MMM dd').format(expense.date);

          // Get the member's specific share of this expense
          final memberSplit = widget.allSplits.firstWhere(
            (s) =>
                s.expenseId == expense.id &&
                s.userEmail.toLowerCase() == widget.member.email.toLowerCase(),
            orElse: () => ExpenseSplit(
              expenseId: expense.id!,
              userEmail: widget.member.email,
              amount: 0,
            ),
          );

          final displayAmount = isPaid ? expense.amount : memberSplit.amount;

          return Column(
            children: [
              ListTile(
                onTap: () {
                  if (expense.isSettlement) {
                    _showSettlementDetailsDialog(expense, themeColor);
                  }
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: expense.isSettlement
                          ? HugeIconsStrokeRounded.agreement02
                          : HugeIconsStrokeRounded.invoice03,
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                ),
                title: Text(
                  expense.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  dt,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                trailing: Text(
                  '$symbol ${formatAmount(displayAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPaid ? Colors.green : Colors.redAccent,
                  ),
                ),
              ),
              if (index < expenses.length - 1)
                Divider(height: 1, indent: 80, color: Colors.grey[50]),
            ],
          );
        }),
      ),
    );
  }

  void _showSettleUpDialog(Color themeColor) {
    final balances = computeMemberBalances(
      widget.allExpenses,
      widget.allSplits,
    );
    final transactions = simplifyDebts(balances);
    final email = widget.member.email.toLowerCase();

    // Filter transactions involving this member
    final myTransactions = transactions
        .where(
          (t) =>
              t.fromEmail.toLowerCase() == email ||
              t.toEmail.toLowerCase() == email,
        )
        .toList();

    if (myTransactions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Settle Up',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Record a payment to settle the balance.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: myTransactions.length,
                  itemBuilder: (ctx, idx) {
                    final tx = myTransactions[idx];
                    final fromMember = widget.allMembers.firstWhere(
                      (m) =>
                          m.email.toLowerCase() == tx.fromEmail.toLowerCase(),
                      orElse: () => User(
                        id: 0,
                        name: tx.fromEmail,
                        email: tx.fromEmail,
                        createdAt: DateTime.now(),
                      ),
                    );
                    final toMember = widget.allMembers.firstWhere(
                      (m) => m.email.toLowerCase() == tx.toEmail.toLowerCase(),
                      orElse: () => User(
                        id: 0,
                        name: tx.toEmail,
                        email: tx.toEmail,
                        createdAt: DateTime.now(),
                      ),
                    );

                    final fromName =
                        fromMember.email.toLowerCase() ==
                            _currentUserEmail?.toLowerCase()
                        ? 'You'
                        : fromMember.name;
                    final toName =
                        toMember.email.toLowerCase() ==
                            _currentUserEmail?.toLowerCase()
                        ? 'You'
                        : toMember.name;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          '$fromName → $toName',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${_getCurrencySymbol()} ${formatAmount(tx.amount)}',
                          style: TextStyle(
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _recordPayment(tx),
                          icon: const HugeIcon(
                            icon: HugeIconsStrokeRounded.thumbsUp,
                            color: Colors.white,
                            size: 18,
                            strokeWidth: 2,
                          ),
                          label: const Text('Settle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
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

  Future<void> _recordPayment(DebtTransaction tx) async {
    final fromMember = widget.allMembers.firstWhere(
      (m) => m.email.toLowerCase() == tx.fromEmail.toLowerCase(),
      orElse: () => User(
        id: 0,
        name: tx.fromEmail,
        email: tx.fromEmail,
        createdAt: DateTime.now(),
      ),
    );
    final toMember = widget.allMembers.firstWhere(
      (m) => m.email.toLowerCase() == tx.toEmail.toLowerCase(),
      orElse: () => User(
        id: 0,
        name: tx.toEmail,
        email: tx.toEmail,
        createdAt: DateTime.now(),
      ),
    );

    final settlementExpense = Expense(
      groupId: widget.group.id!,
      description: 'Settlement: ${fromMember.name} to ${toMember.name}',
      amount: tx.amount,
      date: DateTime.now(),
      paidByEmail: tx.fromEmail,
      splitType: 'settlement',
      createdAt: DateTime.now(),
      isSettlement: true,
    );

    final splits = [
      ExpenseSplit(expenseId: 0, userEmail: tx.toEmail, amount: tx.amount),
    ];

    await DatabaseService.insertExpense(settlementExpense, splits);

    if (mounted) {
      Navigator.pop(context); // Close bottom sheet
      Navigator.pop(context, true); // Close detail screen with refresh signal
    }
  }

  void _showSettlementDetailsDialog(Expense expense, Color themeColor) {
    final symbol = _getCurrencySymbol();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIconsStrokeRounded.agreement02,
                      color: themeColor,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Settlement Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Description', expense.description),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Amount',
                        '$symbol ${formatAmount(expense.amount)}',
                        valueColor: themeColor,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Date',
                        DateFormat('dd MMM yyyy, hh:mm a').format(expense.date),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDeleteSettlement(expense, themeColor);
                  },
                  child: const Text(
                    'Delete Settlement',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteSettlement(Expense expense, Color themeColor) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 5),
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
                const Text(
                  'Delete Settlement?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will permanently delete this settlement record. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
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
                        onPressed: () async {
                          if (expense.id != null) {
                            await DatabaseService.deleteExpense(expense.id!);
                            if (mounted) {
                              Navigator.pop(ctx); // Close dialog
                              Navigator.pop(
                                context,
                                true,
                              ); // Close screen & refresh
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveMemberDialog(Color themeColor) {
    final symbol = _getCurrencySymbol();
    final hasUnsettledBalance = _balance.balance.abs() > 0.01;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: hasUnsettledBalance
                      ? HugeIconsStrokeRounded.alertDiamond
                      : HugeIconsStrokeRounded.userRemove01,
                  color: themeColor,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  hasUnsettledBalance
                      ? 'Cannot Remove'
                      : 'Remove ${widget.member.name}?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasUnsettledBalance
                      ? '${widget.member.name} has an unsettled balance of $symbol ${formatAmount(_balance.balance.abs())}. Please settle up first.'
                      : 'This member will no longer be active in the group, but their expense history will be preserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (hasUnsettledBalance)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Got it'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await DatabaseService.removeMemberFromGroup(
                              widget.group.id!,
                              widget.member.email,
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                Navigator.pop(
                                  context,
                                  true,
                                ); // Go back to group detail and signal refresh
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Remove',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
