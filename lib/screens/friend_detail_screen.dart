import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../utils/debt_engine.dart';
import '../utils/split_engine.dart';

class FriendDetailScreen extends StatefulWidget {
  final User friend;

  const FriendDetailScreen({super.key, required this.friend});

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  double _toCollect = 0.0;
  double _toPay = 0.0;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _debts = [];
  Map<String, String> _userNames = {};
  String? _currentUserEmail;
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadActivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService.getFriendDetailedActivity(
      widget.friend.email,
    );
    final allUsers = await DatabaseService.getAllUsers();
    final nameMap = {for (var u in allUsers) u.email.toLowerCase(): u.name};
    final currentEmail = await SessionService.getUserEmail();

    setState(() {
      _toCollect = data['toCollect'] ?? 0.0;
      _toPay = data['toPay'] ?? 0.0;
      _groups = List<Map<String, dynamic>>.from(data['groupBreakdown'] ?? []);
      _debts = List<Map<String, dynamic>>.from(
        data['friendTransactions'] ?? [],
      );
      _userNames = nameMap;
      _currentUserEmail = currentEmail;
      _isLoading = false;
    });
    final symbol = await SessionService.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
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
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFECECEC),
          body: Column(
            children: [
              // Header
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 25),
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
                          tag: 'friend-avatar-${widget.friend.email}',
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              widget.friend.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.friend.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.friend.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Badge Row inside Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildHeaderBadge(
                                  'To Receive',
                                  _toCollect,
                                  HugeIconsStrokeRounded.arrowDown02,
                                  Colors.green[50]!,
                                  Colors.green[200]!,
                                  Colors.green[800]!,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildHeaderBadge(
                                  'To Pay',
                                  _toPay,
                                  HugeIconsStrokeRounded.arrowUp02,
                                  Colors.red[50]!,
                                  Colors.red[200]!,
                                  Colors.red[800]!,
                                ),
                              ),
                            ],
                          ),
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

              // Content Area
              Expanded(
                child: Column(
                  children: [
                    // Tab Bar
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
                          dividerHeight: 0,
                          padding: const EdgeInsets.all(3),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: HugeIconsStrokeRounded.userGroup,
                                    size: 16,
                                    color: _tabController.index == 0
                                        ? Colors.white
                                        : Colors.grey[600]!,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('Groups'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: HugeIconsStrokeRounded.user,
                                    size: 16,
                                    color: _tabController.index == 1
                                        ? Colors.white
                                        : Colors.grey[600]!,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('Friends'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tab View
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [_buildGroupsTab(), _buildFriendsTab()],
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(
    String label,
    double amount,
    dynamic icon,
    Color bgColor,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, color: textColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                Text(
                  '$_currencySymbol${formatAmount(amount)}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    if (_groups.isEmpty) {
      return _buildEmptyState(
        'No group membership',
        HugeIconsStrokeRounded.userGroup,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final item = _groups[index];
        final Group group = item['group'];
        final double balance = item['balance'];
        final isPositive = balance > 0;

        return GestureDetector(
          onTap: () => _showGroupSimplifiedDebts(group),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: HugeIcon(
                    icon: HugeIconsStrokeRounded.userGroup,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        balance.abs() < 0.01
                            ? 'Settled'
                            : (isPositive
                                  ? 'Gets $_currencySymbol${formatAmount(balance)}'
                                  : 'Pays $_currencySymbol${formatAmount(balance.abs())}'),
                        style: TextStyle(
                          color: balance.abs() < 0.01
                              ? Colors.grey
                              : (isPositive
                                    ? Colors.green[600]
                                    : Colors.orange[800]),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const HugeIcon(
                  icon: HugeIconsStrokeRounded.arrowRight01,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGroupSimplifiedDebts(Group group) async {
    final themeColor = Theme.of(context).primaryColor;
    if (group.id == null) return;

    setState(() => _isLoading = true);
    final expenses = await DatabaseService.getGroupExpenses(group.id!);
    final splits = await DatabaseService.getAllExpenseSplitsForGroup(group.id!);
    final members = await DatabaseService.getGroupMembers(group.id!);

    final Map<String, String> emailToName = {
      for (var m in members) m.email.toLowerCase(): m.name,
    };

    final balances = computeMemberBalances(expenses, splits);
    final allTransactions = simplifyDebts(balances);

    // Filter only for this friend
    final friendEmail = widget.friend.email.toLowerCase();
    final transactions = allTransactions
        .where(
          (tx) =>
              tx.fromEmail.toLowerCase() == friendEmail ||
              tx.toEmail.toLowerCase() == friendEmail,
        )
        .toList();

    setState(() => _isLoading = false);

    final symbol = _currencySymbol;

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
                    Text(
                      '${group.name} Settlements',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                          'All settled up!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final fromEmail = tx.fromEmail.toLowerCase();
                        final toEmail = tx.toEmail.toLowerCase();

                        final fromName =
                            fromEmail == _currentUserEmail?.toLowerCase()
                            ? 'You'
                            : (emailToName[fromEmail] ?? tx.fromEmail);
                        final toName =
                            toEmail == _currentUserEmail?.toLowerCase()
                            ? 'You'
                            : (emailToName[toEmail] ?? tx.toEmail);
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
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
                                  ],
                                ),
                              ),
                              Text(
                                '$symbol${formatAmount(tx.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
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
  }

  Widget _buildFriendsTab() {
    if (_debts.isEmpty) {
      return _buildEmptyState(
        'No outstanding balances',
        HugeIconsStrokeRounded.user,
      );
    }

    // Aggregate debts by other person
    final friendEmail = widget.friend.email.toLowerCase();
    final Map<String, double> personBalances = {};

    for (var tx in _debts) {
      final isOwedToFriend = tx['to'].toLowerCase() == friendEmail;
      final otherEmail = (isOwedToFriend ? tx['from'] : tx['to'])
          .toString()
          .toLowerCase();
      final amount = tx['amount'] as double;
      final netForPerson = isOwedToFriend ? amount : -amount;

      personBalances[otherEmail] =
          (personBalances[otherEmail] ?? 0) + netForPerson;
    }

    final sortedEmails = personBalances.keys.toList()
      ..sort(
        (a, b) => personBalances[b]!.abs().compareTo(personBalances[a]!.abs()),
      );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: sortedEmails.length,
      itemBuilder: (context, index) {
        final otherEmail = sortedEmails[index];
        final balance = personBalances[otherEmail]!;
        final isPositive = balance > 0;
        final String displayName =
            otherEmail == _currentUserEmail?.toLowerCase()
            ? 'You'
            : (_userNames[otherEmail] ?? otherEmail);

        return GestureDetector(
          onTap: () => _showFriendshipBreakdown(otherEmail, displayName),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      (isPositive ? Colors.green[600] : Colors.orange[800])!
                          .withValues(alpha: 0.1),
                  child: HugeIcon(
                    icon: isPositive
                        ? HugeIconsStrokeRounded.arrowDown02
                        : HugeIconsStrokeRounded.arrowUp02,
                    color: isPositive
                        ? Colors.green[600]!
                        : Colors.orange[800]!,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        balance.abs() < 0.01
                            ? 'Settled'
                            : (isPositive
                                  ? 'Pays ${widget.friend.name} $_currencySymbol${formatAmount(balance)}'
                                  : '${widget.friend.name} pays $_currencySymbol${formatAmount(balance.abs())}'),
                        style: TextStyle(
                          color: balance.abs() < 0.01
                              ? Colors.grey
                              : (isPositive
                                    ? Colors.green[600]
                                    : Colors.orange[800]),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const HugeIcon(
                  icon: HugeIconsStrokeRounded.arrowRight01,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFriendshipBreakdown(String otherEmail, String otherName) {
    final themeColor = Theme.of(context).primaryColor;
    final friendEmail = widget.friend.email.toLowerCase();

    // Group transactions by groupId
    final List<Map<String, dynamic>> personBreakdown = _debts.where((tx) {
      final f = tx['from'].toLowerCase();
      final t = tx['to'].toLowerCase();
      final o = otherEmail.toLowerCase();
      return (f == friendEmail && t == o) || (t == friendEmail && f == o);
    }).toList();

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
                      icon: HugeIconsStrokeRounded.userGroup,
                      color: themeColor,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.friend.name} & $otherName',
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
                        final isOwedToFriend =
                            tx['to'].toLowerCase() == friendEmail;

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    RichText(
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: isOwedToFriend
                                                ? otherName
                                                : widget.friend.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(text: ' pays '),
                                          TextSpan(
                                            text: isOwedToFriend
                                                ? widget.friend.name
                                                : otherName,
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
                                '$_currencySymbol${formatAmount(amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOwedToFriend
                                      ? Colors.green[600]
                                      : Colors.red[800],
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
  }

  Widget _buildEmptyState(String message, dynamic icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: icon, size: 60, color: Colors.grey[300]!),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
