import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Config/api.dart';

class AppColors {
  static const Color appBarBackground = Color(0xFF1F3E8A);
  static const Color appBarTitle = Colors.white;
  static const Color appBarIcon = Colors.white;
  static const Color pageBackground = Color(0xFFF5F5F5);
  static const Color welcomeCardBackground = Color(0xFF2C4EA3);
  static const Color welcomeCardTitle = Colors.white;
  static const Color welcomeCardSubtitle = Colors.white70;
  static const Color menuLabelText = Color(0xFF1A1A1A);
  static const Color menuCardBackground = Colors.white;
  static const Color menuCardBorder = Color(0xFFE0E0E0);
  static const Color menuCardShadow = Color(0x14000000);
  static const Color menuCardText = Color(0xFF1A1A1A);
  static const Color calendarLabelText = Color(0xFF1A1A1A);
  static const Color calendarBackground = Colors.white;
  static const Color calendarBorder = Color(0xFFE0E0E0);
  static const Color calendarGridText = Color(0xFF666666);
  static const Color calendarTodayBg = Color(0xFF1F3E8A);
  static const Color calendarTodayText = Colors.white;
}

class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.appBarTitle,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle welcomeTitle = TextStyle(
    color: AppColors.welcomeCardTitle,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle welcomeSubtitle = TextStyle(
    color: AppColors.welcomeCardSubtitle,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sectionLabel = TextStyle(
    color: AppColors.menuLabelText,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle menuItemText = TextStyle(
    color: AppColors.menuCardText,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle calendarMonthYear = TextStyle(
    color: AppColors.calendarGridText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle calendarDate = TextStyle(
    color: AppColors.calendarGridText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomepage> {
  // State
  DateTime _selectedDate = DateTime.now();
  bool _isLoggingOut = false;
  String _userName = 'Loading...';
  String _userRole = 'Student';
  bool _isLoadingUser = true;

  // Lifecycle
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Helper Methods
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

    if (cutIndex != -1) {
      return fullName.substring(0, cutIndex).trim();
    }
    return fullName;
  }

  Future<void> fetchUserData() async {
    try {
      final result = await ApiService.getCurrentUser();

      if (result['success'] && result['data'] != null) {
        final fullName = result['data']['full_name'] ?? 'User';
        final firstName = extractFirstName(fullName);

        setState(() {
          _userName = firstName;
          _userRole = 'Student';
          _isLoadingUser = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', firstName);
      } else {
        loadUserFromStorage();
      }
    } catch (e) {
      print('Error fetching user: $e');
      loadUserFromStorage();
    }
  }

  Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name') ?? 'Student';

      setState(() {
        _userName = savedName;
        _userRole = 'Student';
        _isLoadingUser = false;
      });
    } catch (e) {
      print('Error loading user from storage: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  // Navigation & Logout
  Future<void> handleLogout() async {
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
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> performLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      await ApiService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  // Calendar Methods
  void previousMonth() {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
      );
    });
  }

  List<int> getCalendarDays() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;

    List<int> days = [];
    for (int i = 0; i < startingWeekday - 1; i++) {
      days.add(0);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i);
    }

    return days;
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: buildAppBar(),
      body: _isLoggingOut
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.appBarBackground,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

  // App Bar
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBarBackground,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.logout, color: AppColors.appBarIcon),
        onPressed: _isLoggingOut ? null : handleLogout,
        tooltip: 'Logout',
      ),
      centerTitle: true,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MyAcademic',
            style: TextStyle(
              color: AppColors.appBarTitle,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'UMPSA',
            style: TextStyle(
              color: AppColors.appBarTitle,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Welcome Card
  Widget buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.welcomeCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLoadingUser
                ? 'Welcome Back!'
                : 'Welcome Back, $_userName!',
            style: AppTextStyles.welcomeTitle,
          ),
          const SizedBox(height: 4),
          Text(
            _userRole,
            style: AppTextStyles.welcomeSubtitle,
          ),
        ],
      ),
    );
  }

  // Menu Section
  Widget buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu',
          style: AppTextStyles.sectionLabel,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              buildMenuCard(
                icon: Icons.school,
                label: 'Subject\nRegistration',
                onTap: () => Navigator.pushNamed(context, '/student-subject'),
              ),
              const SizedBox(width: 12),
              buildMenuCard(
                icon: Icons.event_note,
                label: 'Co-Curriculum\nRegistration',
                onTap: () => Navigator.pushNamed(context, '/student-activities'),
              ),
              const SizedBox(width: 12),
              buildMenuCard(
                icon: Icons.how_to_reg,
                label: 'Class\nAttendance',
                onTap: () => Navigator.pushNamed(context, '/student-class-attendance'),
              ),
              const SizedBox(width: 12),
              buildMenuCard(
                icon: Icons.checklist,
                label: 'Co-Curriculum\nAttendance',
                onTap: () => Navigator.pushNamed(context, '/student-cocurriculum-attendance'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildMenuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.appBarBackground,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.menuItemText,
            ),
          ],
        ),
      ),
    );
  }

  // Calendar Section
  Widget buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calendar',
          style: AppTextStyles.sectionLabel,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.calendarBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.calendarBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.menuCardShadow,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              buildMonthYearNavigation(),
              const SizedBox(height: 16),
              buildCalendarGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildMonthYearNavigation() {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: previousMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Row(
          children: [
            Text(
              monthNames[_selectedDate.month - 1],
              style: AppTextStyles.calendarMonthYear,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedDate.year.toString(),
              style: AppTextStyles.calendarMonthYear,
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: nextMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget buildCalendarGrid() {
    final days = getCalendarDays();
    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays
              .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: days.map((day) {
            final isToday = day > 0 &&
                day == today.day &&
                _selectedDate.month == today.month &&
                _selectedDate.year == today.year;

            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.calendarTodayBg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  day > 0 ? day.toString() : '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isToday
                        ? AppColors.calendarTodayText
                        : (day > 0
                            ? AppColors.calendarGridText
                            : Colors.transparent),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
