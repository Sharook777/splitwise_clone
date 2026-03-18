import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../services/session_service.dart';
import '../services/database_service.dart';
import '../utils/debt_engine.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _userName;
  double _totalToCollect = 0.0;
  double _totalToPay = 0.0;
  List<Map<String, dynamic>> _dashboardGroups = [];
  List<Map<String, dynamic>> _dashboardFriends = [];
  String? _currentUserEmail;
  Map<String, String> _userNames = {};
  bool _isLoading = true;
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final name = await SessionService.getUserName();
    final email = await SessionService.getUserEmail();

    if (email != null) {
      final activity = await DatabaseService.getFriendDetailedActivity(email);
      final balances = await DatabaseService.getDashboardBalances(email);
      final allUsers = await DatabaseService.getAllUsers();
      final nameMap = {for (var u in allUsers) u.email.toLowerCase(): u.name};

      if (mounted) {
        setState(() {
          _userName = name ?? 'User';
          _currentUserEmail = email;
          _userNames = nameMap;
          _totalToCollect = activity['toCollect'] ?? 0.0;
          _totalToPay = activity['toPay'] ?? 0.0;
          _dashboardGroups = balances['groups'] ?? [];
          _dashboardFriends = balances['friends'] ?? [];
          _isLoading = false;
        });
        // Load currency symbol separately to not block main data if possible, or just wait
        final symbol = await SessionService.getCurrencySymbol();
        if (mounted) {
          setState(() {
            _currencySymbol = symbol;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _userName = name ?? 'User';
          _isLoading = false;
        });
      }
    }
  }

  String formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFECECEC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFECECEC),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // 1. Greeting
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hey, ',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: _userName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 45,
                      height: 45,
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: Transform.scale(
                        scale: 1,
                        child: Image.asset(
                          'assets/splash_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // 2. Campaign Box
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/onboarding_banner.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Split bills effortlessly.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Share expenses with your friends.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 3. Personal Balance Summary
                const Text(
                  'Your Personal Balance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIconsStrokeRounded.arrowDown02,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You Collect',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),

                                Text(
                                  '$_currencySymbol${formatAmount(_totalToCollect)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIconsStrokeRounded.arrowUp02,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You Pay',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$_currencySymbol${formatAmount(_totalToPay)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // // 4. Quick Actions
                // Row(
                //   children: [
                //     _buildQuickAction(
                //       context,
                //       HugeIconsStrokeRounded.add01,
                //       'Add Expense',
                //       Colors.blue,
                //       () {
                //         // Navigate to add expense (needs common add expense logic)
                //       },
                //     ),
                //     const SizedBox(width: 15),
                //     _buildQuickAction(
                //       context,
                //       HugeIconsStrokeRounded.userGroup,
                //       'New Group',
                //       Colors.purple,
                //       () {
                //         // Navigate to create group
                //       },
                //     ),
                //   ],
                // ),

                // 5. Pending Balances
                const Text(
                  'Your Pending Settlements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_dashboardGroups.isEmpty && _dashboardFriends.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 40,
                          color: themeColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You are all settled up!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Groups
                  if (_dashboardGroups.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(0),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'WITH GROUPS',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _dashboardGroups.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _dashboardGroups[index];
                        final double balance = item['balance'];
                        final isPositive = balance > 0;
                        return _buildBalanceItem(
                          context,
                          item['name'],
                          'Group',
                          balance,
                          isPositive,
                          HugeIconsStrokeRounded.userGroup,
                          onTap: () => _showGroupSimplifiedDebts(
                            item['id'] as int,
                            item['name'],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Friends
                  if (_dashboardFriends.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(0),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'WITH FRIENDS',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _dashboardFriends.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _dashboardFriends[index];
                        final double balance = item['balance'];
                        final isPositive = balance > 0;
                        return _buildBalanceItem(
                          context,
                          item['name'],
                          'Friend',
                          balance,
                          isPositive,
                          HugeIconsStrokeRounded.user,
                          onTap: () => _showFriendshipBreakdown(
                            item['email'],
                            item['name'],
                          ),
                        );
                      },
                    ),
                  ],
                ],

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String title,
    String subtitle,
    double balance,
    bool isPositive,
    dynamic icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isPositive ? Colors.green : Colors.red).withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HugeIcon(
                icon: icon,
                color: isPositive ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_currencySymbol${formatAmount(balance.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  isPositive ? 'owes you' : 'you owes',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 10),
              const HugeIcon(
                icon: HugeIconsStrokeRounded.arrowRight01,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showGroupSimplifiedDebts(int groupId, String groupName) async {
    final themeColor = Theme.of(context).primaryColor;

    // Show a minimal overlay loading or just fetch quietly
    // to avoid flickering the entire dashboard
    final expenses = await DatabaseService.getGroupExpenses(groupId);
    final splits = await DatabaseService.getAllExpenseSplitsForGroup(groupId);
    final members = await DatabaseService.getGroupMembers(groupId);

    final Map<String, String> emailToName = {
      for (var m in members) m.email.toLowerCase(): m.name,
    };

    final balances = computeMemberBalances(expenses, splits);
    final allTransactions = simplifyDebts(balances);

    // Filter only for current user
    final userEmail = _currentUserEmail?.toLowerCase() ?? '';
    final transactions = allTransactions
        .where(
          (tx) =>
              tx.fromEmail.toLowerCase() == userEmail ||
              tx.toEmail.toLowerCase() == userEmail,
        )
        .toList();
    if (!mounted) return;
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        isDismissible: false,
        builder: (ctx) {
          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
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
                      Expanded(
                        child: Text(
                          '$groupName Settlements',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simplified group debts for easier settlement.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          HugeIcon(
                            icon: HugeIconsStrokeRounded.checkmarkCircle02,
                            color: themeColor,
                            size: 50,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Everyone is settled up!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final fromEmail = tx.fromEmail.toLowerCase();
                          final toEmail = tx.toEmail.toLowerCase();

                          final fromName =
                              fromEmail == _currentUserEmail?.toLowerCase()
                              ? 'You'
                              : (_userNames[fromEmail] ??
                                    emailToName[fromEmail] ??
                                    tx.fromEmail);
                          final toName =
                              toEmail == _currentUserEmail?.toLowerCase()
                              ? 'You'
                              : (_userNames[toEmail] ??
                                    emailToName[toEmail] ??
                                    tx.toEmail);
                          final isOwedToMe =
                              tx.toEmail.toLowerCase() ==
                              _currentUserEmail?.toLowerCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
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
                                            const TextSpan(text: ' owes '),
                                            TextSpan(
                                              text: toName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$_currencySymbol${formatAmount(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isOwedToMe
                                        ? Colors.green[600]
                                        : Colors.red[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settlements: $e')),
        );
      }
    }
  }

  void _showFriendshipBreakdown(String otherEmail, String otherName) async {
    final themeColor = Theme.of(context).primaryColor;

    try {
      final data = await DatabaseService.getFriendDetailedActivity(otherEmail);
      final List<Map<String, dynamic>> personBreakdown =
          List<Map<String, dynamic>>.from(data['friendTransactions'] ?? []);

      if (!mounted) return;

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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
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
                        icon: HugeIconsStrokeRounded.userGroup,
                        color: themeColor,
                        size: 25,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You & $otherName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Group-wise breakdown of settlements.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (personBreakdown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('No direct group settlements found.'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: personBreakdown.length,
                        itemBuilder: (context, index) {
                          final tx = personBreakdown[index];
                          final String groupName =
                              tx['groupName'] ?? 'Unknown Group';
                          final double amount = tx['amount'] as double;
                          final isOwedToMe =
                              tx['to'].toLowerCase() ==
                              _currentUserEmail?.toLowerCase();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        groupName.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isOwedToMe
                                            ? '$otherName owes'
                                            : 'You owe',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        isOwedToMe ? 'You' : otherName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$_currencySymbol${formatAmount(amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isOwedToMe
                                        ? Colors.green[600]
                                        : Colors.red[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading breakdown: $e')));
      }
    }
  }

  Widget _buildQuickAction(
    BuildContext context,
    dynamic icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              HugeIcon(icon: icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
