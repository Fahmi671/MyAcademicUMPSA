import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Config/api.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomepage> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoggingOut = false;
  bool _isLoadingUser = true;
  String _userName = 'Loading...';
  String _userRole = 'Student';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  String extractFirstName(String fullName) {
    fullName = fullName.trim();
    final lowerName = fullName.toLowerCase();
    final binIndex = lowerName.indexOf(' bin ');
    final bintiIndex = lowerName.indexOf(' binti ');

    int cutIndex = -1;
    if (binIndex != -1 && bintiIndex != -1) {
      cutIndex = binIndex < bintiIndex ? binIndex : bintiIndex;
    } else if (binIndex != -1) {
      cutIndex = binIndex;
    } else if (bintiIndex != -1) {
      cutIndex = bintiIndex;
    }
    return cutIndex == -1 ? fullName : fullName.substring(0, cutIndex).trim();
  }

  Future<void> fetchUserData() async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success'] && result['data'] != null) {
        final fullName = result['data']['full_name'] ?? 'Student';
        final firstName = extractFirstName(fullName.toString());
        if (mounted) {
          setState(() {
            _userName = firstName;
            _userRole = 'Student';
            _isLoadingUser = false;
          });
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', firstName);
      } else {
        await loadUserFromStorage();
      }
    } catch (_) {
      await loadUserFromStorage();
    }
  }

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Student';
        _userRole = 'Student';
        _isLoadingUser = false;
      });
    }
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
    final startingWeekday = firstDay.weekday;
    final days = <int>[];
    for (int i = 0; i < startingWeekday - 1; i++) {
      days.add(0);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i);
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F3E8A),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _isLoggingOut ? null : handleLogout,
        ),
        centerTitle: true,
        title: const Column(
          children: [
            Text('MyAcademic', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            Text('UMPSA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: _isLoggingOut
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F3E8A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C4EA3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingUser ? 'Welcome Back!' : 'Welcome Back, $_userName!',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(_userRole, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Menu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/student-subject'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.school, size: 36, color: Color(0xFF1F3E8A)),
                                SizedBox(height: 8),
                                Text('Subject\nRegistration', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/student-activities'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.event_note, size: 36, color: Color(0xFF1F3E8A)),
                                SizedBox(height: 8),
                                Text(
                                  'Co-Curriculum\nRegistration',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Calendar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
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
                              onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1)),
                              icon: const Icon(Icons.arrow_back_ios, size: 16),
                            ),
                            Text(
                              '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1)),
                              icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 7,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: getCalendarDays().map((day) {
                            final now = DateTime.now();
                            final isToday = day > 0 &&
                                day == now.day &&
                                _selectedDate.month == now.month &&
                                _selectedDate.year == now.year;
                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isToday ? const Color(0xFF1F3E8A) : Colors.transparent,
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
                  ),
                ],
              ),
            ),
    );
  }
}
