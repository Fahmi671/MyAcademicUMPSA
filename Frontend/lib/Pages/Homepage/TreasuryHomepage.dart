import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Config/api.dart';
import 'StudentHomepage.dart'; // Using AppColors and AppTextStyles from here

class TreasuryHomepage extends StatefulWidget {
  const TreasuryHomepage({super.key});

  @override
  State<TreasuryHomepage> createState() => _TreasuryHomepageState();
}

class _TreasuryHomepageState extends State<TreasuryHomepage> {
  String _userName = 'Loading...';
  String _userRole = 'Treasury';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success'] && result['data'] != null) {
        final fullName = result['data']['full_name'] ?? 'Treasury';
        final firstName = fullName.split(' ')[0];

        setState(() {
          _userName = firstName;
          _userRole = 'Treasury';
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _userName = 'Siti';
          _userRole = 'Treasury';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Siti';
        _userRole = 'Treasury';
        _isLoadingUser = false;
      });
    }
  }

  void _handleLogout() async {
    await ApiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A2D87), // Purple background
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _handleLogout,
        ),
        title: Column(
          children: const [
            Text('MyAcademic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('UMPSA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildWelcomeCard(),
            const SizedBox(height: 24),
            buildMenuSection(),
            const SizedBox(height: 24),
            buildCalendarSection(),
          ],
        ),
      ),
    );
  }

  Widget buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6A2D87), // Purple background from screenshot
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLoadingUser ? 'Welcome Back!' : 'Welcome Back, $_userName!',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _userRole,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/treasury-ledger'),
          child: Container(
            width: 110,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.menuCardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.menuCardBorder, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.menuCardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.menu_book, size: 32, color: Colors.black),
                SizedBox(height: 8),
                Text(
                  'Student\nLedger',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Calendar', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_left),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: 'Sep',
                        items: ['Sep'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) {},
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: '2025',
                        items: ['2025'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) {},
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 16),
              // Dummy calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.2,
                ),
                itemCount: 35,
                itemBuilder: (ctx, idx) {
                  final day = idx - 6 + 1;
                  if (day < 1 || day > 30) return const SizedBox();
                  final isSelected = day == 9 || day == 13;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black87 : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
