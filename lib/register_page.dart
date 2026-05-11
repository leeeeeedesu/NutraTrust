import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'models/user_profile.dart';
import 'services/realtime_database_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleInitialController =
      TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _countryController.text = 'Philippines';
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create Firebase Auth user
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        if (!mounted) return;

        // Save user record and profile data to Firestore and Realtime Database
        final firstName = _firstNameController.text.trim();
        final middleInitial = _middleInitialController.text.trim();
        final lastName = _lastNameController.text.trim();

        await _saveUserRecords(
          uid: userCredential.user!.uid,
          email: _emailController.text.trim(),
          firstName: firstName,
          middleInitial: middleInitial,
          lastName: lastName,
          phoneNumber: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          barangay: _barangayController.text.trim(),
          municipality: _municipalityController.text.trim(),
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
        );

        debugPrint('Saved name: $firstName $middleInitial $lastName');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String message = 'Registration failed. Please try again.';
        if (e.code == 'email-already-in-use') {
          message = 'The email address is already in use.';
        } else if (e.code == 'weak-password') {
          message = 'The password is too weak.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    }
  }

  Future<void> _saveUserRecords({
    required String uid,
    required String email,
    required String firstName,
    required String middleInitial,
    required String lastName,
    required String phoneNumber,
    required String street,
    required String barangay,
    required String municipality,
    required String city,
    required String country,
  }) async {
    final firestoreRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid);
    final firestoreData = {
      'uid': uid,
      'email': email,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final profile = UserProfile(
      uid: uid,
      firstName: firstName,
      middleInitial: middleInitial,
      lastName: lastName,
      phoneNumber: phoneNumber,
      street: street,
      barangay: barangay,
      municipality: municipality,
      city: city,
      country: country,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await firestoreRef.set(firestoreData);
      await RealtimeDatabaseService.createUserRecord(
        uid: uid,
        email: email,
        role: 'customer',
      );
      await RealtimeDatabaseService.saveUserProfile(profile);
      await RealtimeDatabaseService.updateUserLocation(uid, {
        'street': street,
        'barangay': barangay,
        'municipality': municipality,
        'city': city,
        'country': country,
      });
    } catch (error) {
      // Roll back Firestore if RTDB creation fails.
      try {
        if ((await firestoreRef.get()).exists) {
          await firestoreRef.delete();
        }
      } catch (_) {
        // ignore rollback failure
      }

      try {
        await RealtimeDatabaseService.usersRef.child(uid).remove();
      } catch (_) {
        // ignore rollback failure
      }

      // Optionally remove the auth user to avoid partial registration.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid == uid) {
        try {
          await currentUser?.delete();
        } catch (_) {
          // ignore auth cleanup failure
        }
      }

      rethrow;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _municipalityController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: const Color(0xFF028B22),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E8B3A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fill in your details to start shopping with NutraTrust.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  labelText: "First Name",
                  hintText: "Enter your first name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter your first name"
                    : null,
              ),
              const SizedBox(height: 16),

              // Middle Initial
              TextFormField(
                controller: _middleInitialController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.text_fields),
                  labelText: "Middle Initial",
                  hintText: "Enter your middle initial (optional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                maxLength: 1,
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: "Last Name",
                  hintText: "Enter your last name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter your last name"
                    : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone),
                  labelText: "Phone Number",
                  hintText:
                      "Enter your phone number (e.g., 09123456789 or +639123456789)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your phone number";
                  }
                  final phone = value.trim();
                  // Philippine phone number validation: starts with +63 or 09, total 11 digits
                  final phoneRegExp = RegExp(r'^(?:\+63|09)\d{9}$');
                  if (!phoneRegExp.hasMatch(phone)) {
                    return "Please enter a valid Philippine phone number (11 digits, starting with 09 or +63)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Street
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.home),
                  labelText: "Street Address",
                  hintText: "Enter your street address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter your street address"
                    : null,
              ),
              const SizedBox(height: 16),

              // Barangay
              TextFormField(
                controller: _barangayController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_city),
                  labelText: "Barangay",
                  hintText: "Enter your barangay",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter your barangay"
                    : null,
              ),
              const SizedBox(height: 16),

              // Municipality
              TextFormField(
                controller: _municipalityController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on),
                  labelText: "Municipality",
                  hintText: "Enter your municipality",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter your municipality"
                    : null,
              ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  labelText: "City",
                  hintText: "Enter your city",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter your city"
                    : null,
              ),
              const SizedBox(height: 16),

              // Country
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.public),
                  labelText: "Country",
                  hintText: "Enter your country",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? "Please enter your country"
                    : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: "Email Address",
                  hintText: "Enter your email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }
                  final emailRegExp = RegExp(
                    r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}",
                  );
                  if (!emailRegExp.hasMatch(value.trim())) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: "Password",
                  hintText: "Minimum 8 characters",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                  if (value.length < 8) {
                    return "Password must be at least 8 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: "Confirm Password",
                  hintText: "Re-enter your password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please confirm your password";
                  }
                  if (value.length < 8) {
                    return "Password must be at least 8 characters";
                  }
                  if (value != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF028B22),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Register"),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}
