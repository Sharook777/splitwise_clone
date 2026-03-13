import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:intl/intl.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/add_member_full_screen_dialog.dart';
import 'add_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  List<User> _members = [];
  bool _isLoadingMembers = true;
  late TabController _tabController;
  late String _groupName;
  String? _currency;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _budget;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _groupName = widget.group.name;
    _currency = widget.group.currency;
    _startDate = widget.group.startDate;
    _endDate = widget.group.endDate;
    _budget = widget.group.budget;
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      if (widget.group.id != null) {
        final members = await DatabaseService.getGroupMembers(widget.group.id!);
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
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
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 30),
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
                        tag: 'group-icon-${widget.group.id}',
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const HugeIcon(
                            icon: HugeIconsStrokeRounded.bitcoinBag,
                            color: Colors.white,
                            size: 25,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${_members.length} Member${_members.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
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
            children: [_buildEmptyActivity(themeColor)],
          ),
          Positioned(
            bottom: 10,
            left: 40,
            right: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpenseScreen(
                      group: widget.group,
                      members: _members,
                    ),
                  ),
                );
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                onTap: () => _showEditGroupNameSheet(themeColor),
              ),
              _buildSettingsDivider(),
              _buildSettingsTile(
                icon: HugeIconsStrokeRounded.dollarSquare,
                title: 'Set Currency',
                subtitle: _currency ?? 'Not set',
                color: themeColor,
                onTap: () => _showSetCurrencyDialog(themeColor),
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
                onTap: () => _showSetBudgetDialog(themeColor),
              ),
              _buildSettingsDivider(),
              _buildSettingsTile(
                icon: HugeIconsStrokeRounded.calendar03,
                title: 'Set Dates',
                subtitle: _formatDateRange(),
                color: themeColor,
                onTap: () => _showSetDatesDialog(themeColor),
              ),
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
          : Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
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

  void _showEditGroupNameSheet(Color themeColor) {
    final controller = TextEditingController(text: _groupName);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
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

  void _showSetCurrencyDialog(Color themeColor) {
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

    showDialog(
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
                                    ? themeColor.withOpacity(0.1)
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

  void _showSetDatesDialog(Color themeColor) {
    DateTime? from = _startDate;
    DateTime? to = _endDate;

    showDialog(
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showSetBudgetDialog(Color themeColor) {
    final controller = TextEditingController(
      text: _budget != null ? _budget!.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

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

  void _showDeleteGroupDialog(Color themeColor) {
    bool confirmed = false;

    showDialog(
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
                                      if (mounted) Navigator.pop(this.context);
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
        children: List.generate(_members.length, (index) {
          final member = _members[index];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: themeColor.withOpacity(0.1),
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
                subtitle: Text(
                  member.email,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                trailing: member.id != widget.group.createdBy
                    ? IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () =>
                            _showRemoveMemberDialog(themeColor, member),
                      )
                    : const SizedBox.shrink(),
              ),
              if (index < _members.length - 1)
                Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                  color: Colors.grey[100],
                ),
            ],
          );
        }),
      ),
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
            icon: HugeIconsStrokeRounded.invoice01,
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
                  icon: HugeIconsStrokeRounded.userRemove01,
                  color: themeColor,
                  size: 60,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Remove Member?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to remove ${member.name} from this group? They will lose access to the group expenses.',
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
                          if (widget.group.id != null) {
                            await DatabaseService.removeMemberFromGroup(
                              widget.group.id!,
                              member.email,
                            );
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

  void _showAddMemberDialog(Color themeColor) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) {
        return AddMemberFullScreenDialog(
          themeColor: themeColor,
          group: widget.group,
          existingMembers: _members,
          onMembersAdded: _loadMembers,
        );
      },
    );
  }
}
