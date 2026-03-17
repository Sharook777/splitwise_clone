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
import '../utils/export_helper.dart';
import '../widgets/add_member_full_screen_dialog.dart';
import 'member_detail_screen.dart';
import 'add_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late Group _currentGroup;
  List<User> _members = [];
  List<Expense> _expenses = [];
  List<ExpenseSplit> _allSplits = [];
  bool _isLoadingMembers = true;
  bool _isLoadingExpenses = true;
  late TabController _tabController;
  late String _groupName;
  String? _currency;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _budget;
  // bool _showInactiveMembers = false;
  List<User> _inactiveMembers = [];

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    _tabController = TabController(length: 3, vsync: this);
    _initGroupData();
    _loadMembers();
    _loadExpenses();

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _initGroupData() {
    _groupName = _currentGroup.name;
    _currency = _currentGroup.currency;
    _startDate = _currentGroup.startDate;
    _endDate = _currentGroup.endDate;
    _budget = _currentGroup.budget;
  }

  Future<void> _refreshGroup() async {
    if (_currentGroup.id != null) {
      final updatedGroup = await DatabaseService.getGroupById(
        _currentGroup.id!,
      );
      if (updatedGroup != null && mounted) {
        setState(() {
          _currentGroup = updatedGroup;
          _initGroupData();
        });
      }
    }
  }

  Future<void> _loadExpenses() async {
    try {
      if (_currentGroup.id != null) {
        final expenses = await DatabaseService.getGroupExpenses(
          _currentGroup.id!,
        );
        final allSplits = await DatabaseService.getAllExpenseSplitsForGroup(
          _currentGroup.id!,
        );
        if (mounted) {
          setState(() {
            _expenses = expenses;
            _allSplits = allSplits;
            _isLoadingExpenses = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      if (mounted) setState(() => _isLoadingExpenses = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      if (_currentGroup.id != null) {
        final activeMembers = await DatabaseService.getGroupMembers(
          _currentGroup.id!,
          includeInactive: false,
        );
        final inactiveMembers = await DatabaseService.getGroupMembers(
          _currentGroup.id!,
          includeInactive: true,
        );

        // Filter inactive members: those that are in 'all' but not in 'active'
        final activeEmails = activeMembers
            .map((m) => m.email.toLowerCase())
            .toSet();
        final filteredInactive = inactiveMembers
            .where((m) => !activeEmails.contains(m.email.toLowerCase()))
            .toList();

        if (mounted) {
          setState(() {
            _members = activeMembers;
            _inactiveMembers = filteredInactive;
            _isLoadingMembers = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading group members: $e');
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

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
            // ── Header ──
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 15),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'group-icon-${_currentGroup.id}',
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const HugeIcon(
                            icon: HugeIconsStrokeRounded.bitcoinBag,
                            color: Colors.white,
                            size: 22,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          // Total Spend Badge
                          Builder(
                            builder: (_) {
                              final double totalAmount = _expenses
                                  .where((e) => !e.isSettlement)
                                  .fold(0.0, (sum, e) => sum + e.amount);
                              final symbol =
                                  _currency != null && _currency!.isNotEmpty
                                  ? _currency!.split(' ').first
                                  : '\$';

                              return Container(
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
                                      icon: HugeIconsStrokeRounded.dollarCircle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$symbol${formatAmount(totalAmount)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Member Count Badge
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
                                  icon: HugeIconsStrokeRounded.userGroup,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_members.length} Member${_members.length != 1 ? 's' : ''}',
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
              ],
            ),

            // ── Tab Bar ──
            Container(
              margin: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
              ),
              child: SizedBox(
                height: 45,
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  indicator: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: BorderRadius.circular(35),
                  dividerHeight: 0,
                  padding: const EdgeInsets.all(3),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            strokeWidth: 2,
                            icon: HugeIconsStrokeRounded.invoice03,
                            size: 16,
                            color: _tabController.index == 0
                                ? Colors.white
                                : Colors.grey[600]!,
                          ),
                          const SizedBox(width: 3),
                          const Text('Expenses'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            strokeWidth: 2,
                            icon: HugeIconsStrokeRounded.userGroup,
                            size: 16,
                            color: _tabController.index == 1
                                ? Colors.white
                                : Colors.grey[600]!,
                          ),
                          const SizedBox(width: 3),
                          const Text('Members'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            strokeWidth: 2,
                            icon: HugeIconsStrokeRounded.settings02,
                            size: 16,
                            color: _tabController.index == 2
                                ? Colors.white
                                : Colors.grey[600]!,
                          ),
                          const SizedBox(width: 3),
                          const Text('Settings'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpensesTab(themeColor),
                  _buildMembersTab(themeColor),
                  _buildSettingsTab(themeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Views ──────────────────────────────────────────

  Widget _buildExpensesTab(Color themeColor) {
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
            children: [
              if (_isLoadingExpenses)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_expenses.isEmpty)
                _buildEmptyActivity(themeColor)
              else
                _buildExpensesList(themeColor),
            ],
          ),
          Positioned(
            bottom: 10,
            left: 40,
            right: 40,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(
                      group: _currentGroup,
                      activeMembers: _members,
                      inactiveMembers: _inactiveMembers,
                    ),
                  ),
                );
                // Refresh expenses and group data if an expense was added
                if (result == true) {
                  _loadExpenses();
                  _refreshGroup();
                }
              },
              icon: const HugeIcon(
                icon: HugeIconsStrokeRounded.addInvoice,
                color: Colors.white,
                size: 20,
                strokeWidth: 2,
              ),
              label: const Text(
                'Add Expense',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(Color themeColor) {
    final symbol = _currency != null && _currency!.isNotEmpty
        ? _currency!.split(' ').first
        : '\$';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(_expenses.length, (index) {
          final expense = _expenses[index];
          final dt = DateFormat('MMM dd').format(expense.date);

          final payer = _members.firstWhere(
            (m) => m.email.toLowerCase() == expense.paidByEmail.toLowerCase(),
            orElse: () => User(
              id: 0,
              name: expense.paidByEmail,
              email: expense.paidByEmail,
              createdAt: DateTime.now(),
            ),
          );

          final payerName = expense.paidByName ?? payer.name;

          return Column(
            children: [
              ListTile(
                onTap: () async {
                  if (expense.id != null) {
                    if (expense.isSettlement) {
                      _showSettlementDetailsDialog(expense, themeColor);
                      return;
                    }

                    final splits = await DatabaseService.getExpenseSplits(
                      expense.id!,
                    );
                    if (mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpenseScreen(
                            group: _currentGroup,
                            activeMembers: _members,
                            inactiveMembers: _inactiveMembers,
                            existingExpense: expense,
                            existingSplits: splits,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadExpenses();
                        _refreshGroup();
                      }
                    }
                  }
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
                  'Paid by $payerName',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$symbol ${formatAmount(expense.amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          dt,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIconsStrokeRounded.delete02,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      onPressed: () => _deleteExpense(expense, themeColor),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showSettlementDetailsDialog(Expense expense, Color themeColor) {
    final symbol = _currency != null && _currency!.isNotEmpty
        ? _currency!.split(' ').first
        : '\$';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIconsStrokeRounded.agreement02,
                    color: themeColor,
                    size: 40,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$symbol ${formatAmount(expense.amount)}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Settled',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expense.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 15),
                  SizedBox(
                    width: 130,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
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

  void _deleteExpense(Expense expense, Color themeColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
                    'Delete Expense?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will permanently delete "${expense.description}" and all its split data. This action cannot be undone.',
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
                              _loadExpenses();
                              _refreshGroup();
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
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
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(Color themeColor) {
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
            children: [_buildMembersSection(themeColor)],
          ),
          Positioned(
            bottom: 10,
            left: 40,
            right: 40,
            child: ElevatedButton.icon(
              onPressed: () => _showAddMemberDialog(themeColor),
              icon: const HugeIcon(
                icon: HugeIconsStrokeRounded.userAdd01,
                color: Colors.white,
                size: 20,
                strokeWidth: 2,
              ),
              label: const Text(
                'Add Member',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(Color themeColor) {
    return SafeArea(
      top: false,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: HugeIconsStrokeRounded.edit02,
                  title: 'Edit Group Name',
                  subtitle: _groupName,
                  color: themeColor,
                  onTap: () async {
                    await _showEditGroupNameSheet(themeColor);
                    _refreshGroup();
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: HugeIconsStrokeRounded.dollarSquare,
                  title: 'Set Currency',
                  subtitle: _currency ?? 'Not set',
                  color: themeColor,
                  onTap: () async {
                    await _showSetCurrencyDialog(themeColor);
                    _refreshGroup();
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: HugeIconsStrokeRounded.invoice03,
                  title: 'Set Budget',
                  subtitle: _budget != null
                      ? '${_currency?.split(' ').first ?? ''} ${_budget!.toStringAsFixed(0)}'
                            .trim()
                      : 'Not set',
                  color: themeColor,
                  onTap: () async {
                    await _showSetBudgetDialog(themeColor);
                    _refreshGroup();
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: HugeIconsStrokeRounded.calendar03,
                  title: 'Set Dates',
                  subtitle: _formatDateRange(),
                  color: themeColor,
                  onTap: () async {
                    await _showSetDatesDialog(themeColor);
                    _refreshGroup();
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: HugeIconsStrokeRounded.aiSheets,
                  title: 'Export as sheet',
                  subtitle: 'Download all expenses as CSV',
                  color: themeColor,
                  onTap: () async {
                    await ExportHelper.exportGroupToCsv(
                      group: _currentGroup,
                      expenses: _expenses,
                      allSplits: _allSplits,
                      members: _members,
                    );
                  },
                ),
                _buildSettingsDivider(),
                // _buildSettingsTile(
                //   icon: HugeIconsStrokeRounded.fileDownload,
                //   title: 'System Backup (.dutch)',
                //   subtitle: 'Export everything for portability',
                //   color: themeColor,
                //   onTap: () async {
                //     await ExportHelper.backupGroupToSystemFile(
                //       group: _currentGroup,
                //       expenses: _expenses,
                //       allSplits: _allSplits,
                //       members: _members,
                //       inactiveMembers: _inactiveMembers,
                //     );
                //   },
                // ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildSettingsTile(
              icon: HugeIconsStrokeRounded.delete02,
              title: 'Delete Group',
              color: Colors.redAccent,
              textColor: Colors.redAccent,
              onTap: () => _showDeleteGroupDialog(themeColor),
              noTail: false,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange() {
    if (_startDate == null && _endDate == null) return 'Not set';
    final fmt = DateFormat('dd MMM yyyy');
    final start = _startDate != null ? fmt.format(_startDate!) : '–';
    final end = _endDate != null ? fmt.format(_endDate!) : '–';
    return '$start → $end';
  }

  // ── Settings Helpers ──────────────────────────────────

  Widget _buildSettingsTile({
    required dynamic icon,
    required String title,
    String? subtitle,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
    bool noTail = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: HugeIcon(icon: icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          : null,
      trailing: !noTail
          ? null
          : HugeIcon(
              icon: HugeIconsStrokeRounded.arrowRight01,
              size: 16,
              color: Colors.grey[400]!,
            ),
      onTap: onTap,
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey[100],
    );
  }

  // ── Bottom Sheets & Dialogs ────────────────────────────

  Future<void> _showEditGroupNameSheet(Color themeColor) {
    final controller = TextEditingController(text: _groupName);
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
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
                              'Edit Group Name',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: HugeIcon(
                                icon: HugeIconsStrokeRounded.cancel01,
                                color: Colors.grey[600]!,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  bottom: 8,
                                ),
                                child: Text(
                                  'Group Name',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              TextFormField(
                                controller: controller,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Please enter a name'
                                    : null,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter group name',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                  prefixIcon: SizedBox(
                                    width: 45,
                                    child: Center(
                                      child: HugeIcon(
                                        icon: HugeIconsStrokeRounded.userGroup,
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
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(
                                      color: themeColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: const BorderSide(
                                      color: Colors.redAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      final newName = controller.text.trim();
                                      if (widget.group.id != null) {
                                        await DatabaseService.updateGroupName(
                                          widget.group.id!,
                                          newName,
                                        );
                                        setState(() => _groupName = newName);
                                        if (ctx.mounted) Navigator.pop(ctx);
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Save',
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
      },
    );
  }

  Future<void> _showSetCurrencyDialog(Color themeColor) {
    final allCurrencies = [
      {'code': '\$ USD', 'name': 'US Dollar'},
      {'code': '₹ INR', 'name': 'Indian Rupee'},
      {'code': '€ EUR', 'name': 'Euro'},
      {'code': '£ GBP', 'name': 'British Pound'},
      {'code': '¥ JPY', 'name': 'Japanese Yen'},
      {'code': 'A\$ AUD', 'name': 'Australian Dollar'},
      {'code': 'C\$ CAD', 'name': 'Canadian Dollar'},
      {'code': 'د.إ AED', 'name': 'UAE Dirham'},
      {'code': 'Fr CHF', 'name': 'Swiss Franc'},
      {'code': '¥ CNY', 'name': 'Chinese Yuan'},
      {'code': 'kr SEK', 'name': 'Swedish Krona'},
      {'code': 'NZ\$ NZD', 'name': 'New Zealand Dollar'},
      {'code': 'Mex\$ MXN', 'name': 'Mexican Peso'},
      {'code': 'S\$ SGD', 'name': 'Singapore Dollar'},
      {'code': 'HK\$ HKD', 'name': 'Hong Kong Dollar'},
      {'code': 'kr NOK', 'name': 'Norwegian Krone'},
      {'code': '₩ KRW', 'name': 'South Korean Won'},
      {'code': '₺ TRY', 'name': 'Turkish Lira'},
      {'code': '₽ RUB', 'name': 'Russian Ruble'},
      {'code': 'R ZAR', 'name': 'South African Rand'},
      {'code': 'R\$ BRL', 'name': 'Brazilian Real'},
      {'code': 'RM MYR', 'name': 'Malaysian Ringgit'},
      {'code': '₱ PHP', 'name': 'Philippine Peso'},
      {'code': 'Rp IDR', 'name': 'Indonesian Rupiah'},
      {'code': '฿ THB', 'name': 'Thai Baht'},
      {'code': '₫ VND', 'name': 'Vietnamese Dong'},
      {'code': '₪ ILS', 'name': 'Israeli New Shekel'},
      {'code': 'Kč CZK', 'name': 'Czech Koruna'},
    ];

    String? selected = _currency;
    List<Map<String, String>> displayedCurrencies = List.from(allCurrencies);
    final searchController = TextEditingController();

    return showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
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
                              'Set Currency',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const HugeIcon(
                              icon: HugeIconsStrokeRounded.cancel01,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose the currency for this group',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search currency...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35),
                            borderSide: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 1,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            final query = val.toLowerCase();
                            displayedCurrencies = allCurrencies.where((c) {
                              return c['code']!.toLowerCase().contains(query) ||
                                  c['name']!.toLowerCase().contains(query);
                            }).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: displayedCurrencies.map((c) {
                          final isSelected = selected == c['code'];
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selected = c['code']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeColor.withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? themeColor
                                      : Colors.grey[100]!,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['code']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isSelected
                                              ? themeColor
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        c['name']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected)
                                    HugeIcon(
                                      icon: HugeIconsStrokeRounded
                                          .checkmarkCircle02,
                                      color: themeColor,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Bottom Actions
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                if (selected != null &&
                                    widget.group.id != null) {
                                  await DatabaseService.updateGroupCurrency(
                                    widget.group.id!,
                                    selected!,
                                  );
                                  setState(() => _currency = selected);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save',
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
          },
        );
      },
    );
  }

  Future<void> _showSetDatesDialog(Color themeColor) {
    DateTime? from = _startDate;
    DateTime? to = _endDate;

    return showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final fmt = DateFormat('dd MMM yyyy');
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Dates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the date range for this group',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    // From Date
                    _buildDateSelector(
                      label: 'From',
                      value: from != null ? fmt.format(from!) : 'Select date',
                      themeColor: themeColor,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: from ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
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
                        if (picked != null) {
                          setDialogState(() => from = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // To Date
                    _buildDateSelector(
                      label: 'To',
                      value: to != null ? fmt.format(to!) : 'Select date',
                      themeColor: themeColor,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: to ?? (from ?? DateTime.now()),
                          firstDate: from ?? DateTime(2020),
                          lastDate: DateTime(2030),
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
                        if (picked != null) {
                          setDialogState(() => to = picked);
                        }
                      },
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
                              if (widget.group.id != null) {
                                await DatabaseService.updateGroupDates(
                                  widget.group.id!,
                                  from,
                                  to,
                                );
                                setState(() {
                                  _startDate = from;
                                  _endDate = to;
                                });
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
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
                              'Save',
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
      },
    );
  }

  Widget _buildDateSelector({
    required String label,
    required String value,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIconsStrokeRounded.calendar03,
              color: themeColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: value == 'Select date'
                          ? Colors.grey[400]
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIconsStrokeRounded.arrowRight01,
              size: 14,
              color: Colors.grey[400]!,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetBudgetDialog(Color themeColor) {
    final controller = TextEditingController(
      text: _budget != null ? _budget!.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Budget',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Enter a budget limit for this group',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'e.g. 5000',
                      prefixIcon: SizedBox(
                        width: 35,
                        height: 35,
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIconsStrokeRounded.invoice03,
                            color: themeColor,
                            size: 20,
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(35),
                        borderSide: BorderSide(color: themeColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final val = double.tryParse(value);
                        if (val == null || val <= 0) {
                          return 'Enter a valid amount';
                        }
                      }
                      return null; // allow empty to clear budget
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                            if (formKey.currentState!.validate() &&
                                widget.group.id != null) {
                              double? newBudget;
                              if (controller.text.isNotEmpty) {
                                newBudget = double.tryParse(controller.text);
                              }
                              await DatabaseService.updateGroupBudget(
                                widget.group.id!,
                                newBudget ?? 0.0,
                              );
                              setState(() => _budget = newBudget);
                              if (ctx.mounted) Navigator.pop(ctx);
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
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteGroupDialog(Color themeColor) {
    bool confirmed = false;

    return showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
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
                      'Delete Group?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will permanently delete "$_groupName" and all its data. This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    // Confirmation checkbox
                    GestureDetector(
                      onTap: () => setDialogState(() => confirmed = !confirmed),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: confirmed,
                              onChanged: (v) =>
                                  setDialogState(() => confirmed = v ?? false),
                              activeColor: themeColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'I confirm I want to delete this group',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                            onPressed: confirmed
                                ? () async {
                                    if (widget.group.id != null) {
                                      await DatabaseService.deleteGroup(
                                        widget.group.id!,
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) Navigator.pop(context);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
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
      },
    );
  }

  // ── Reusable Widgets ──────────────────────────────────

  Widget _buildMembersSection(Color themeColor) {
    if (_isLoadingMembers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No members yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Group Members'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSimplifyDebtsDialog(themeColor),
                  icon: HugeIcon(
                    icon: HugeIconsStrokeRounded.aiMagic,
                    color: themeColor,
                    size: 20,
                  ),
                  label: const Text('Simplify'),
                  style: TextButton.styleFrom(
                    foregroundColor: themeColor,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_members.length, (index) {
            final member = _members[index];
            final balances = computeMemberBalances(_expenses, _allSplits);
            final memberBalance = balances[member.email.toLowerCase()];
            final symbol = _currency != null && _currency!.isNotEmpty
                ? _currency!.split(' ').first
                : '\$';

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetailScreen(
                          group: _currentGroup,
                          member: member,
                          allExpenses: _expenses,
                          allSplits: _allSplits,
                          allMembers: _members,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadExpenses();
                      _loadMembers(); // Reload members too in case status changed
                      _refreshGroup();
                    }
                  },
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: themeColor.withValues(alpha: 0.1),
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: memberBalance != null && memberBalance.totalPaid > 0
                      ? Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            children: [
                              const TextSpan(text: 'Spent '),
                              TextSpan(
                                text:
                                    '$symbol ${formatAmount(memberBalance.totalPaid)}',
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          'No payments yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (memberBalance != null &&
                          memberBalance.balance.abs() > 0.01)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$symbol ${formatAmount(memberBalance.balance.abs())}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: memberBalance.balance > 0
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                            ),
                            Text(
                              memberBalance.balance > 0 ? 'gets back' : 'owes',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 8),
                      // Use a fixed width container for alignment
                      SizedBox(
                        width: 40,
                        child: member.id != _currentGroup.createdBy
                            ? IconButton(
                                icon: const HugeIcon(
                                  icon: HugeIconsStrokeRounded.removeCircle,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _showRemoveMemberDialog(themeColor, member),
                                visualDensity: VisualDensity.compact,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                if (index < _members.length - 1)
                  Divider(height: 1, indent: 60, color: Colors.grey[100]),
              ],
            );
          }),

          // if (_inactiveMembers.isNotEmpty) ...[
          //   InkWell(
          //     onTap: () =>
          //         setState(() => _showInactiveMembers = !_showInactiveMembers),
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 16,
          //         vertical: 8,
          //       ),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           Text(
          //             'Removed Members (${_inactiveMembers.length})',
          //             style: TextStyle(
          //               fontSize: 12,
          //               fontWeight: FontWeight.bold,
          //               color: Colors.grey[500],
          //               letterSpacing: 0.5,
          //             ),
          //           ),
          //           HugeIcon(
          //             icon: !_showInactiveMembers
          //                 ? HugeIconsStrokeRounded.arrowDown01
          //                 : HugeIconsStrokeRounded.arrowUp01,
          //             color: Colors.grey[500],
          //             size: 20,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          //   if (_showInactiveMembers)
          //     ..._inactiveMembers.map((member) {
          //       return ListTile(
          //         contentPadding: const EdgeInsets.symmetric(
          //           horizontal: 8,
          //           vertical: 0,
          //         ),
          //         leading: CircleAvatar(
          //           radius: 16,
          //           backgroundColor: Colors.grey[200],
          //           child: Text(
          //             member.name[0].toUpperCase(),
          //             style: const TextStyle(color: Colors.grey, fontSize: 12),
          //           ),
          //         ),
          //         title: Text(
          //           member.name,
          //           style: TextStyle(color: Colors.grey[600], fontSize: 14),
          //         ),
          //         subtitle: Text(
          //           member.email,
          //           style: TextStyle(color: Colors.grey[500], fontSize: 12),
          //         ),
          //         trailing: SizedBox(
          //           width: 40,
          //           child: IconButton(
          //             icon: HugeIcon(
          //               icon: HugeIconsStrokeRounded.userAdd02,
          //               color: themeColor,
          //               size: 20,
          //             ),
          //             onPressed: () =>
          //                 _showRestoreMemberDialog(themeColor, member),
          //             visualDensity: VisualDensity.compact,
          //           ),
          //         ),
          //       );
          //     }),
          //   const SizedBox(height: 10),
          // ],
        ],
      ),
    );
  }

  void _restoreMember(User member) async {
    if (_currentGroup.id != null) {
      await DatabaseService.restoreMemberToGroup(
        _currentGroup.id!,
        member.email,
      );
      _loadMembers();
    }
  }

  void _showRestoreMemberDialog(Color themeColor, User member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIconsStrokeRounded.userAdd02,
                    color: themeColor,
                    size: 60,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Back Member?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to add ${member.name} back to this group? They will regain access to all group expenses.',
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
                          onPressed: () {
                            _restoreMember(member);
                            Navigator.pop(ctx);
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
                            'Add Back',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyActivity(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIconsStrokeRounded.invoice03,
            size: 50,
            color: Colors.grey[300]!,
          ),
          const SizedBox(height: 16),
          Text(
            'No group expenses yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Split an expense to get started',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(Color themeColor, User member) {
    final balances = computeMemberBalances(_expenses, _allSplits);
    final memberEmail = member.email.toLowerCase();
    final memberBalance = balances[memberEmail];
    final hasUnsettledBalance =
        memberBalance != null && memberBalance.balance.abs() > 0.01;

    final hasTransactions =
        _expenses.any((e) => e.paidByEmail.toLowerCase() == memberEmail) ||
        _allSplits.any((s) => s.userEmail.toLowerCase() == memberEmail);

    final symbol = _currency != null && _currency!.isNotEmpty
        ? _currency!.split(' ').first
        : '\$';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: hasUnsettledBalance || hasTransactions
                        ? HugeIconsStrokeRounded.alertDiamond
                        : HugeIconsStrokeRounded.delete02,
                    color: themeColor,
                    size: 50,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hasUnsettledBalance
                        ? 'Cannot Remove Member'
                        : 'Delete Member?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (hasUnsettledBalance) ...[
                    Text(
                      '${member.name} has an unsettled balance of $symbol ${formatAmount(memberBalance.balance.abs())}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memberBalance.balance > 0
                          ? 'They are owed money by other members. Please settle all debts.'
                          : 'They owe money to other members. Please settle all debts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else if (hasTransactions)
                    Text(
                      '${member.name} has transaction history. You can not remove them from the group.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    )
                  else
                    Text(
                      '${member.name} hasn\'t participated in any expenses. They will be removed from the group.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 24),
                  if (hasUnsettledBalance || hasTransactions)
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
                          elevation: 0,
                        ),
                        child: const Text(
                          'Got it',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                              if (_currentGroup.id != null) {
                                if (hasTransactions) {
                                  await DatabaseService.removeMemberFromGroup(
                                    _currentGroup.id!,
                                    member.email,
                                  );
                                } else {
                                  await DatabaseService.hardDeleteMemberFromGroup(
                                    _currentGroup.id!,
                                    member.email,
                                  );
                                }
                                _loadMembers();
                                if (ctx.mounted) Navigator.pop(ctx);
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
                            child: Text(
                              'Delete',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSimplifyDebtsDialog(Color themeColor) {
    final balances = computeMemberBalances(_expenses, _allSplits);
    final transactions = simplifyDebts(balances);

    final symbol = _currency != null && _currency!.isNotEmpty
        ? _currency!.split(' ').first
        : '\$';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIconsStrokeRounded.aiMagic,
                      color: themeColor,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Simplify Debts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'We simplified the group debts into ${transactions.length} total transactions.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        HugeIcon(
                          icon: HugeIconsStrokeRounded.checkmarkCircle02,
                          color: themeColor,
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'All settled up!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: transactions.length,
                      itemBuilder: (ctx, i) {
                        final tx = transactions[i];
                        final from = _members
                            .firstWhere(
                              (m) =>
                                  m.email.toLowerCase() ==
                                  tx.fromEmail.toLowerCase(),
                              orElse: () => User(
                                id: 0,
                                name: tx.fromEmail,
                                email: tx.fromEmail,
                                createdAt: DateTime.now(),
                              ),
                            )
                            .name;
                        final to = _members
                            .firstWhere(
                              (m) =>
                                  m.email.toLowerCase() ==
                                  tx.toEmail.toLowerCase(),
                              orElse: () => User(
                                id: 0,
                                name: tx.toEmail,
                                email: tx.toEmail,
                                createdAt: DateTime.now(),
                              ),
                            )
                            .name;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  from,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 45,
                                child: Center(
                                  child: HugeIcon(
                                    icon: HugeIconsStrokeRounded.arrowRight02,
                                    size: 22,
                                    color: themeColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  to,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 85,
                                child: Text(
                                  '$symbol ${formatAmount(tx.amount)}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  void _showAddMemberDialog(Color themeColor) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) {
        return AddMemberFullScreenDialog(
          themeColor: themeColor,
          group: _currentGroup,
          existingMembers: _members,
          onMembersAdded: _loadMembers,
        );
      },
    );
  }
}
