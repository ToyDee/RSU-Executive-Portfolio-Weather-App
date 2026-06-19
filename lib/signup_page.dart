  import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'app_security.dart';
  import 'employees_page.dart';
  import 'login_page.dart';

  class SignUpPage extends StatefulWidget {
    const SignUpPage({super.key});

    @override
    State<SignUpPage> createState() => _SignUpPageState();
  }

  class _SignUpPageState extends State<SignUpPage> {
    final _formKey = GlobalKey<FormState>();
    final _fullNameController    = TextEditingController();
    final _usernameController    = TextEditingController();
    final _passwordController    = TextEditingController();
    final _confirmController     = TextEditingController();
    bool _obscurePassword = true;
    bool _obscureConfirm  = true;
    bool _isLoading = false;

    @override
    void dispose() {
      _fullNameController.dispose();
      _usernameController.dispose();
      _passwordController.dispose();
      _confirmController.dispose();
      super.dispose();
    }

    Future<void> _confirmAndSave() async {
      if (!_formKey.currentState!.validate()) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Registration',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text(
            'Register as "${_fullNameController.text.trim()}"?\n\nUsername: ${_usernameController.text.trim()}',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('full_name', _fullNameController.text.trim());
      await prefs.setString('username', _usernameController.text.trim());
      // IMPROVEMENT: store hash, not plain text
      await prefs.setString('password', AppSecurity.hashPassword(_passwordController.text));
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const EmployeesPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B5E20)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF1B5E20).withOpacity(0.15),
                              blurRadius: 20, offset: const Offset(0, 6),
                            )],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Image.asset('Assets/Images/RSU_Logo.png'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Create Account', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
                      ),
                      const SizedBox(height: 6),
                      Text('Fill in the details below', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF1B5E20)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1B5E20)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Username is required';
                          if (v.trim().length < 3) return 'At least 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1B5E20)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined, color: Colors.grey),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 4) return 'At least 4 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _confirmAndSave(),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1B5E20)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined, color: Colors.grey),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _confirmAndSave,
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?',
                              style: TextStyle(color: Colors.grey.shade600)),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) => const LoginPage())),
                            child: const Text('Login',
                                style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }