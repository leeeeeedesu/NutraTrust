import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loaderController;

  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // Text animation starts after logo animation
    _textController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loaderFade = CurvedAnimation(
      parent: _loaderController,
      curve: Curves.easeIn,
    );

    // Sequence
    _logoController.forward().then((_) {
      _textController.forward().then((_) {
        _loaderController.forward();
      });
    });

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 89, 222, 120),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: Image.asset(
                'assets/NutraTrustnobg.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 24),

            // Tagline
            FadeTransition(
              opacity: _textFade,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: "Welcome to NutraTrust,\n"),
                      const TextSpan(text: "Where every "),
                      TextSpan(
                        text: "GAINS",
                        style: const TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: " are built and backed with "),
                      TextSpan(
                        text: "NATURE",
                        style: const TextStyle(
                          color: Color(0xFF028B22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: "."),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Loader
            FadeTransition(
              opacity: _loaderFade,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
