import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import '../utils/page_transitions.dart';
import '../utils/nav_controller.dart';
import '../services/database_service.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _currency;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await SessionService.getCurrency();
    setState(() {
      _currency = currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFECECEC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: themeColor,
        body: Column(
          children: [
            // Header Section (Fixed)
            Container(
              width: double.infinity,
              color: themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderIcon(
                          HugeIconsStrokeRounded.arrowLeft01,
                          onTap: () => NavController.setIndex(0),
                        ),
                        _buildHeaderIcon(
                          HugeIconsStrokeRounded.logout01,
                          onTap: () async {
                            await AuthService.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                AnimatedPageRoute(page: const WelcomeScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Profile Image
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: FutureBuilder<String?>(
                        future: SessionService.getUserName(),
                        builder: (context, snapshot) {
                          final initial = (snapshot.data ?? '').isNotEmpty
                              ? snapshot.data![0].toUpperCase()
                              : 'U';
                          return CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.8,
                            ),
                            child: Text(
                              initial,
                              style: TextStyle(fontSize: 25, color: themeColor),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FutureBuilder<String?>(
                          future: SessionService.getUserName(),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'User Name',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 1),
                        FutureBuilder<String?>(
                          future: SessionService.getUserEmail(),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'user@email.com',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
            // Content Container (Scrollable)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFECECEC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Cards Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildInfoCard(
                              'Currency',
                              HugeIconsStrokeRounded.dollarSquare,
                              Colors.green[50] ?? Colors.green,
                              Colors.green[700] ?? Colors.green,
                              subtitle: _currency ?? 'Not set',
                              onTap: () async {
                                await _showSetCurrencyDialog(themeColor);
                                _loadCurrency();
                              },
                            ),
                            _buildInfoCard(
                              'Clear Data',
                              HugeIconsStrokeRounded.delete02,
                              Colors.red[50] ?? Colors.red,
                              Colors.red[700] ?? Colors.red,
                              subtitle: 'Erase all data',
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Clear All Data?'),
                                    content: const Text(
                                      'All your data will be deleted permanently. This action is irreversible.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Clear',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await DatabaseService.clearNonUserData();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Data cleared successfully',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            _buildInfoCard(
                              'Rate DUTCH',
                              HugeIconsStrokeRounded.startUp01,
                              Colors.amber[100] ?? Colors.amber,
                              Colors.amber[700] ?? Colors.amber,
                            ),
                            _buildInfoCard(
                              'App Version',
                              HugeIconsStrokeRounded.softwareLicense,
                              Colors.yellow[50] ?? Colors.yellow,
                              Colors.yellow[700] ?? Colors.yellow,
                              subtitle: '1.5.0+1',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(dynamic icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: HugeIcon(
          icon: icon,
          color: Colors.black,
          size: 24,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    dynamic icon,
    Color bgColor,
    Color iconColor, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: HugeIcon(
                icon: icon,
                color: iconColor,
                size: 24,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showSetCurrencyDialog(Color themeColor) {
    final allCurrencies = [
      {'code': r'$ USD', 'name': 'US Dollar'},
      {'code': '₹ INR', 'name': 'Indian Rupee'},
      {'code': '€ EUR', 'name': 'Euro'},
      {'code': '£ GBP', 'name': 'British Pound'},
      {'code': '¥ JPY', 'name': 'Japanese Yen'},
      {'code': r'A$ AUD', 'name': 'Australian Dollar'},
      {'code': r'C$ CAD', 'name': 'Canadian Dollar'},
      {'code': 'د.إ AED', 'name': 'UAE Dirham'},
      {'code': 'Fr CHF', 'name': 'Swiss Franc'},
      {'code': '¥ CNY', 'name': 'Chinese Yuan'},
      {'code': 'kr SEK', 'name': 'Swedish Krona'},
      {'code': r'NZ$ NZD', 'name': 'New Zealand Dollar'},
      {'code': r'Mex$ MXN', 'name': 'Mexican Peso'},
      {'code': r'S$ SGD', 'name': 'Singapore Dollar'},
      {'code': r'HK$ HKD', 'name': 'Hong Kong Dollar'},
      {'code': 'kr NOK', 'name': 'Norwegian Krone'},
      {'code': '₩ KRW', 'name': 'South Korean Won'},
      {'code': '₺ TRY', 'name': 'Turkish Lira'},
      {'code': '₽ RUB', 'name': 'Russian Ruble'},
      {'code': 'R ZAR', 'name': 'South African Rand'},
      {'code': r'R$ BRL', 'name': 'Brazilian Real'},
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
                          'Choose your preferred currency',
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
                                if (selected != null) {
                                  await SessionService.saveCurrency(selected!);
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
}
