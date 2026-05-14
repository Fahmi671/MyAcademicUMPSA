import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Config/api.dart';

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
    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (result['success']) {
      // Verify role matches selected role
      if (result['data']['role'] == _selectedRole) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result['data']['token']);
        await prefs.setString('user_role', result['data']['role']);
        await prefs.setString('user_name', result['data']['full_name']);
        await prefs.setInt('user_id', result['data']['user_id']);

        if (mounted) {
          navigateToRoleHome(result['data']['role']?.toString());
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
  }

  void navigateToRoleHome(String? role) {
    String? routeName;
    switch (role) {
      case 'facultyregistrar':
        routeName = '/registrar-homepage';
        break;
      case 'lecturer':
        routeName = '/lecturer-homepage';
        break;
      case 'student':
        routeName = '/student-homepage';
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ══════════════════════════════════════════════════════
              //  LOGO
              // ══════════════════════════════════════════════════════
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A5F5F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════
              //  TITLE
              // ══════════════════════════════════════════════════════
              const Text(
                'MyAcademic UMPSA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Portal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),

              // ══════════════════════════════════════════════════════
              //  ROLE SELECTION
              // ══════════════════════════════════════════════════════
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Role',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      underline: Container(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'facultyregistrar',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 20,
                                color: Color(0xFF1A5F5F),
                              ),
                              SizedBox(width: 12),
                              Text('Faculty Registrar'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'lecturer',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.school,
                                size: 20,
                                color: Color(0xFF1A5F5F),
                              ),
                              SizedBox(width: 12),
                              Text('Lecturer'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'student',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Color(0xFF1A5F5F),
                              ),
                              SizedBox(width: 12),
                              Text('Student'),
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
              ),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════
              //  EMAIL FIELD
              // ══════════════════════════════════════════════════════
              TextField(
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
                      color: Color(0xFF1A5F5F),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ══════════════════════════════════════════════════════
              //  PASSWORD FIELD
              // ══════════════════════════════════════════════════════
              TextField(
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
                      color: Color(0xFF1A5F5F),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // ══════════════════════════════════════════════════════
              //  ERROR MESSAGE
              // ══════════════════════════════���═══════════════════════
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════
              //  LOGIN BUTTON
              // ══════════════════════════════════════════════════════
              ElevatedButton(
                onPressed: _isLoading ? null : handleLogin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF1A5F5F),
                  disabledBackgroundColor: Colors.grey,
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}