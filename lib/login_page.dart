import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/realtime_database_service.dart';
import 'admin/admin_dashboard.dart';
import 'register_page.dart';
import 'reset_password.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  static const Set<String> _fallbackAdminEmails = {
    'admin@gmail.com',
    'godoyleebron3@gmail.com',
  };

  Future<void> login(String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Firebase returned no user after sign-in.',
        );
      }

      bool isAdmin = false;
      try {
        final accountData = await RealtimeDatabaseService.getUserAccountProfile(
          user.uid,
        );
        final accountRole = accountData?['role']?.toString();
        final accountIsActive = accountData?['isActive'] == true;
        debugPrint('Admin role: $accountRole');
        debugPrint('Active status: $accountIsActive');

        if (accountRole == 'admin' || accountRole == 'mega_admin') {
          isAdmin = accountIsActive || accountRole != null;
        } else {
          isAdmin = await _isAdminUser(user);
        }
      } catch (error) {
        debugPrint('Admin check failed: $error');
        isAdmin = false;
      }

      if (!isAdmin) {
        isAdmin = _fallbackAdminEmails.contains(email.toLowerCase());
      }

      if (!mounted) return;
      final String successMessage = isAdmin
          ? 'Admin login successful! Signed in as ${user.email}'
          : 'Login successful! Welcome ${user.email}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isAdmin ? const AdminDashboardPage() : const HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      await login(email, password);
    }
  }

  Future<bool> _isAdminUser(User? user) async {
    if (user == null) return false;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data();
        final role = data?['role']?.toString();
        final isActive = data?['isActive'] == true;
        debugPrint('Admin role: $role');
        debugPrint('Active status: $isActive');
        return isActive == true || role != null;
      }

      final query = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final role = data['role']?.toString();
        final isActive = data['isActive'] == true;
        debugPrint('Admin role: $role');
        debugPrint('Active status: $isActive');
        return isActive == true || role != null;
      }

      final groupQuery = await FirebaseFirestore.instance
          .collectionGroup('admin')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (groupQuery.docs.isNotEmpty) {
        final data = groupQuery.docs.first.data();
        final role = data['role']?.toString();
        final isActive = data['isActive'] == true;
        debugPrint('Admin role: $role');
        debugPrint('Active status: $isActive');
        return isActive == true || role != null;
      }

      final accountData = await RealtimeDatabaseService.getUserAccountProfile(
        user.uid,
      );
      final accountRole = accountData?['role']?.toString();
      final accountIsActive = accountData?['isActive'] == true;
      debugPrint('Admin role: $accountRole');
      debugPrint('Active status: $accountIsActive');
      if (accountRole == 'admin' || accountRole == 'mega_admin') {
        return accountIsActive || accountRole != null;
      }

      return false;
    } catch (error) {
      debugPrint('Admin check error: $error');
      return false;
    }
  }

  void _register() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/NutraTrustnobg.png', width: 180, height: 180),
              const SizedBox(height: 16),

              // Tagline
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(
                    fontSize: 10,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                  children: [
                    const TextSpan(
                      text: "Built for ",
                      style: TextStyle(decoration: TextDecoration.none),
                    ),
                    const TextSpan(
                      text: "GAINS.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6b4226),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const TextSpan(
                      text: " Backed by ",
                      style: TextStyle(decoration: TextDecoration.none),
                    ),
                    const TextSpan(
                      text: "NATURE.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF028B22),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Log in or Sign up",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF028B22),
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  hintText: "Enter your email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Enter your password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your password";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF028B22)),
                  ),
                ),
              ),

              // Login and Register buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF028B22),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text("Login"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF028B22),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text("Register"),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text("or log in with"),
              const SizedBox(height: 12),

              // Social media login buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Facebook login pressed"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.facebook, color: Colors.white),
                      label: const Text("Facebook"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Google login pressed")),
                        );
                      },
                      icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                      label: const Text("Google"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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
  }
}
