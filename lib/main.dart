import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firebaseOptions = Firebase.app().options;
  debugPrint(
    'Firebase initialized: appName=${Firebase.app().name}, projectId=${firebaseOptions.projectId}, apiKey=${firebaseOptions.apiKey}',
  );
  if (firebaseOptions.authDomain != null &&
      firebaseOptions.authDomain!.isNotEmpty) {
    debugPrint('Auth domain: ${firebaseOptions.authDomain}');
  } else {
    debugPrint('Auth domain: not configured in Firebase options');
  }
  debugPrint('Auth domain: ${Firebase.app().options.authDomain}');

  // Activate App Check using debug providers in development builds.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutraTrust',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
