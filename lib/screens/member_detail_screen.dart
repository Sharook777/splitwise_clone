import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/debt_engine.dart';
import '../utils/split_engine.dart';
import '../services/session_service.dart';

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
  late List<Expense> _localExpenses;
  late List<ExpenseSplit> _localSplits;
  bool _anySettlementDone = false;
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _localExpenses = widget.allExpenses;
    _localSplits = widget.allSplits;
    _loadCurrencySymbol();
    _computeData();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await SessionService.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
  }

  void _computeData() {
    final email = widget.member.email.toLowerCase();

    // Expenses paid by this member
    _paidExpenses = _localExpenses
        .where((e) => e.paidByEmail.toLowerCase() == email)
        .toList();

    // Expenses borrowed by this member (where they are in the splits)
    final borrowedExpenseIds = _localSplits
        .where((s) => s.userEmail.toLowerCase() == email)
        .map((s) => s.expenseId)
        .toSet();

    _borrowedExpenses = _localExpenses
        .where(
          (e) =>
              borrowedExpenseIds.contains(e.id) &&
              e.paidByEmail.toLowerCase() != email,
        )
        .toList();

    // Total spent
    _totalSpent = _paidExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Balance
    final balances = computeMemberBalances(_localExpenses, _localSplits);
    _balance = balances[email] ?? MemberBalance(email: email);
  }

  Future<void> _refreshData() async {
    final expenses = await DatabaseService.getGroupExpenses(widget.group.id!);
    final splits = await DatabaseService.getAllExpenseSplitsForGroup(
      widget.group.id!,
    );

    if (mounted) {
      setState(() {
        _localExpenses = expenses;
        _localSplits = splits;
        _computeData();
      });
    }
  }

  double _totalSpent = 0;

  String get _displayName => widget.member.name;

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final symbol = _currencySymbol;
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
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            widget.member.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
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
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          // Balance Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: balance.abs() < 0.01
                                      ? HugeIconsStrokeRounded.checkmarkCircle02
                                      : (balance >= 0
                                            ? HugeIconsStrokeRounded.arrowDown02
                                            : HugeIconsStrokeRounded.arrowUp02),
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  balance.abs() < 0.01
                                      ? 'Settled'
                                      : '$symbol${formatAmount(balance.abs())} ${balance >= 0 ? "get" : "pay"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Total Spent Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIconsStrokeRounded.wallet03,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Spent: $symbol${formatAmount(_totalSpent)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (balance.abs() > 0.01) ...[
                        const SizedBox(height: 16),
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
                    onTap: () => Navigator.pop(context, _anySettlementDone),
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
              ],
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
                children: [
                  _buildSectionTitle('Payments $_displayName done'),
                  if (_paidExpenses.isEmpty)
                    _buildEmptyState('No payments done yet')
                  else
                    _buildExpenseList(
                      _paidExpenses,
                      themeColor,
                      symbol,
                      isPaid: true,
                    ),

                  const SizedBox(height: 16),

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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(expenses.length, (index) {
          final expense = expenses[index];
          final dt = DateFormat('MMM dd').format(expense.date);

          // Get the member's specific share of this expense
          final memberSplit = _localSplits.firstWhere(
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
                  _showSettlementDetailsDialog(expense, themeColor);
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                leading: Container(
                  width: 45,
                  height: 45,
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
                    fontSize: 15,
                    height: 1.2,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final balances = computeMemberBalances(
              _localExpenses,
              _localSplits,
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

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settle Up',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Record a payment to settle the balance.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(ctx, true);
                        },
                        icon: HugeIcon(
                          icon: HugeIconsStrokeRounded.cancel01,
                          color: Colors.grey[400]!,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  if (myTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            HugeIcon(
                              icon: HugeIconsStrokeRounded.checkmarkCircle02,
                              color: themeColor,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'All settled up!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: myTransactions.length,
                        itemBuilder: (ctx, idx) {
                          final tx = myTransactions[idx];
                          final fromMember = widget.allMembers.firstWhere(
                            (m) =>
                                m.email.toLowerCase() ==
                                tx.fromEmail.toLowerCase(),
                            orElse: () => User(
                              id: 0,
                              name: tx.fromEmail,
                              email: tx.fromEmail,
                              createdAt: DateTime.now(),
                            ),
                          );
                          final toMember = widget.allMembers.firstWhere(
                            (m) =>
                                m.email.toLowerCase() ==
                                tx.toEmail.toLowerCase(),
                            orElse: () => User(
                              id: 0,
                              name: tx.toEmail,
                              email: tx.toEmail,
                              createdAt: DateTime.now(),
                            ),
                          );

                          final fromName = fromMember.name;
                          final toName = toMember.name;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              title: RichText(
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: fromName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(text: ' pays '),
                                    TextSpan(
                                      text: toName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Text(
                                '$_currencySymbol ${formatAmount(tx.amount)}',
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () =>
                                    _recordPayment(tx, setModalState),
                                icon: const HugeIcon(
                                  icon: HugeIconsStrokeRounded.thumbsUp,
                                  color: Colors.white,
                                  size: 18,
                                  strokeWidth: 2,
                                ),
                                label: const Text('Settle Up'),
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
      },
    );
  }

  Future<void> _recordPayment(
    DebtTransaction tx,
    StateSetter setModalState,
  ) async {
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
      _anySettlementDone = true;
      await _refreshData();
      setModalState(() {});
    }
  }

  void _showSettlementDetailsDialog(Expense expense, Color themeColor) {
    final symbol = _currencySymbol;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIconsStrokeRounded.agreement02,
                        color: themeColor,
                        size: 25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Expense',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    expense.isSettlement
                        ? 'Settled'
                        : (expense.paidByEmail.toLowerCase() ==
                                  widget.member.email.toLowerCase()
                              ? '$_displayName paid'
                              : '$_displayName borrowed from ${widget.allMembers.firstWhere(
                                  (m) => m.email.toLowerCase() == expense.paidByEmail.toLowerCase(),
                                  orElse: () => User(name: "Someone", email: "", id: 0),
                                ).name}'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Description', expense.description),
                        const SizedBox(height: 10),
                        _buildDetailRow('Amount', () {
                          if (expense.isSettlement) {
                            return '$symbol ${formatAmount(expense.amount)}';
                          }
                          final isPaid =
                              expense.paidByEmail.toLowerCase() ==
                              widget.member.email.toLowerCase();
                          if (isPaid) {
                            return '$symbol ${formatAmount(expense.amount)}';
                          } else {
                            final split = _localSplits.firstWhere(
                              (s) =>
                                  s.expenseId == expense.id &&
                                  s.userEmail.toLowerCase() ==
                                      widget.member.email.toLowerCase(),
                              orElse: () => ExpenseSplit(
                                expenseId: expense.id!,
                                userEmail: widget.member.email,
                                amount: 0,
                              ),
                            );
                            return '$symbol ${formatAmount(split.amount)}';
                          }
                        }(), valueColor: Colors.red[600]),
                        if (!expense.isSettlement &&
                            expense.paidByEmail.toLowerCase() ==
                                widget.member.email.toLowerCase())
                          (() {
                            final split = _localSplits.firstWhere(
                              (s) =>
                                  s.expenseId == expense.id &&
                                  s.userEmail.toLowerCase() ==
                                      widget.member.email.toLowerCase(),
                              orElse: () => ExpenseSplit(
                                expenseId: expense.id!,
                                userEmail: widget.member.email,
                                amount: 0,
                              ),
                            );
                            if (split.amount > 0.01) {
                              return Column(
                                children: [
                                  const SizedBox(height: 10),
                                  _buildDetailRow(
                                    'Your Share',
                                    '$symbol ${formatAmount(split.amount)}',
                                    valueColor: Colors.green[800],
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          'Date',
                          DateFormat('dd MMM yyyy').format(expense.date),
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
                ],
              ),
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
}
