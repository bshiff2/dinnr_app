import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'chatPage.dart';
import 'profile.dart';
import 'navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the status bar text color to white
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness: Brightness.light, // Set icons to light mode
      statusBarBrightness: Brightness.dark, // For iOS devices
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase not configured',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Run: flutterfire configure\n\nOr download GoogleService-Info.plist from Firebase Console and add it to ios/Runner/',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text('Error: $e', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dinnr',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory, // Disable ripple effect globally
        ),
        home: NavBar(child: HomePageUI()),
        routes: {
          '/home': (context) => NavBar(child: HomePageUI()),
          '/chat': (context) => NavBar(child: ChatOngoing()),
          '/profile': (context) => NavBar(child: Profile()),
        },
      ),
    );
  }
}
