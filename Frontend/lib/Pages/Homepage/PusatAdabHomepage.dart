import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Config/api.dart';

class PusatAdabHomepage extends StatefulWidget {
  const PusatAdabHomepage({super.key});

  @override
  State<PusatAdabHomepage> createState() => _PusatAdabHomepageState();
}

class _PusatAdabHomepageState extends State<PusatAdabHomepage> {
  bool _isLoggingOut = false;
  String _userName = 'Anas';
  DateTime _selectedDate = DateTime.now();

  static const Color green = Color(0xFF3F8F3F);
  static const Color darkGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Anas';
    });
  }

  Future<void> performLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      await ApiService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  void handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              performLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<int> getCalendarDays() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    final days = <int>[];

    for (int i = 0; i < startWeekday; i++) {
      days.add(0);
    }

    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i);
    }

    return days;
  }

  void previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
  }

  void nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
  }

  Widget buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD0D0D0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: Colors.black),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCalendar() {
  final days = getCalendarDays();

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: previousMonth,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
            ),
            Text(
              '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: nextMonth,
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: days.map((day) {
            final now = DateTime.now();

            final isToday = day > 0 &&
                day == now.day &&
                _selectedDate.month == now.month &&
                _selectedDate.year == now.year;

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isToday ? green : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  day > 0 ? '$day' : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isToday ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: green,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _isLoggingOut ? null : handleLogout,
        ),
        centerTitle: true,
        title: const Text(
          'Pusat Adab\nUMPSA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/umpsa_logo.png',
              width: 38,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.account_balance, color: Colors.white);
              },
            ),
          ),
        ],
      ),
      body: _isLoggingOut
          ? const Center(child: CircularProgressIndicator(color: green))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back, $_userName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Pusat Adab',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      buildMenuCard(
                        icon: Icons.calendar_month,
                        title: 'Co-Curriculum\nManagement',
                        onTap: () {
                          Navigator.pushNamed(context, '/adab-manage-activity');
                        },
                      ),
                      const SizedBox(width: 12),
                      buildMenuCard(
                        icon: Icons.groups,
                        title: 'Co-Curriculum\nAttendance',
                        onTap: () {
                          Navigator.pushNamed(context, '/pusat-adab-attendance');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Calendar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildCalendar(),
                ],
              ),
            ),
    );
  }
}