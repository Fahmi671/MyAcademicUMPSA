import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Config/api.dart';

// ============================================================
//  CONFIGURATION
// ============================================================

class AppColors {
  // App bar
  static const Color appBarBackground = Color(0xFF1A5F5F);
  static const Color appBarIcon = Colors.white;

  // Page
  static const Color pageBackground = Colors.white;

  // Logo container
  static const Color logoBackground = Color(0xFF1A5F5F);
  static const Color logoIcon = Colors.white;

  // Title
  static const Color titleText = Color(0xFF1A1A1A);
  static const Color subtitleText = Colors.grey;

  // Role section
  static const Color roleLabel = Color(0xFF1A1A1A);
  static const Color roleIcon = Color(0xFF1A5F5F);
  static const Color roleBorder = Color(0xFFE0E0E0);

  // Text fields
  static const Color fieldBorder = Color(0xFFE0E0E0);
  static const Color fieldFocus = Color(0xFF1A5F5F);
  static const Color fieldIcon = Colors.grey;

  // Error
  static const Color errorBackground = Colors.red;
  static const Color errorIcon = Colors.red;
  static const Color errorText = Colors.red;

  // Button
  static const Color buttonBackground = Color(0xFF1A5F5F);
  static const Color buttonText = Colors.white;
  static const Color buttonDisabled = Colors.grey;
}

class AppTextStyles {
  static const TextStyle titleText = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.titleText,
  );

  static const TextStyle subtitleText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.subtitleText,
  );

  static const TextStyle roleLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.roleLabel,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonText = TextStyle(
    color: AppColors.buttonText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}

class AppRoutes {
  static const String registrarHomepage = '/registrar-homepage';
  static const String lecturerHomepage = '/lecturer-homepage';
  static const String studentHomepage = '/student-homepage';
  static const String pusatAdabHomepage = '/pusat-adab-homepage';
  static const String treasuryHomepage = '/treasury-homepage';
  static const String login = '/login';
}

// ============================================================
//  MAIN PAGE WIDGET
// ============================================================

class LoginInterface extends StatefulWidget {
  const LoginInterface({super.key});

  @override
  State<LoginInterface> createState() => _LoginInterfaceState();
}

class _LoginInterfaceState extends State<LoginInterface> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedRole = 'facultyregistrar';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result['success']) {
        final userRole = result['data']['role']?.toString();

        if (userRole == _selectedRole) {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('auth_token', result['data']['token']);
          await prefs.setString('user_role', result['data']['role']);
          await prefs.setString('user_name', result['data']['full_name']);
          await prefs.setInt('user_id', result['data']['user_id']);

          if (mounted) {
            navigateToRoleHome(userRole);
          }
        } else {
          setState(() {
            _errorMessage = 'Your role does not match the selected role';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void navigateToRoleHome(String? role) {
    String? routeName;

    switch (role) {
      case 'facultyregistrar':
        routeName = AppRoutes.registrarHomepage;
        break;

      case 'lecturer':
        routeName = AppRoutes.lecturerHomepage;
        break;

      case 'student':
        routeName = AppRoutes.studentHomepage;
        break;

      case 'pusatadab':
        routeName = AppRoutes.pusatAdabHomepage;
        break;

      case 'treasury':
        routeName = AppRoutes.treasuryHomepage;
        break;

      default:
        setState(() {
          _errorMessage = 'Invalid role detected';
          _isLoading = false;
        });
        return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildLogo(),
              const SizedBox(height: 24),
              buildTitle(),
              const SizedBox(height: 48),
              buildRoleSelection(),
              const SizedBox(height: 24),
              buildEmailField(),
              const SizedBox(height: 16),
              buildPasswordField(),
              if (_errorMessage != null) buildErrorMessage(),
              const SizedBox(height: 24),
              buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.logoBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.shield,
        color: AppColors.logoIcon,
        size: 48,
      ),
    );
  }

  Widget buildTitle() {
    return const Column(
      children: [
        Text(
          'MyAcademic UMPSA',
          style: AppTextStyles.titleText,
        ),
        SizedBox(height: 8),
        Text(
          'Portal',
          style: AppTextStyles.subtitleText,
        ),
      ],
    );
  }

  Widget buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Role', style: AppTextStyles.roleLabel),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.roleBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedRole,
            isExpanded: true,
            underline: Container(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            items: const [
              DropdownMenuItem(
                value: 'facultyregistrar',
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 20,
                      color: AppColors.roleIcon,
                    ),
                    SizedBox(width: 12),
                    Text('Faculty Registrar'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'lecturer',
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 20,
                      color: AppColors.roleIcon,
                    ),
                    SizedBox(width: 12),
                    Text('Lecturer'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'student',
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.roleIcon,
                    ),
                    SizedBox(width: 12),
                    Text('Student'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'pusatadab',
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 20,
                      color: AppColors.roleIcon,
                    ),
                    SizedBox(width: 12),
                    Text('Pusat Adab'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'treasury',
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 20,
                      color: AppColors.roleIcon,
                    ),
                    SizedBox(width: 12),
                    Text('Treasury'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRole = value;
                  _errorMessage = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.fieldFocus,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.fieldFocus,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget buildErrorMessage() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.errorBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.errorBackground.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.errorIcon,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.errorText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : handleLogin,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: AppColors.buttonBackground,
        disabledBackgroundColor: AppColors.buttonDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.buttonText,
                ),
              ),
            )
          : const Text(
              'Login',
              style: AppTextStyles.buttonText,
            ),
    );
  }
}