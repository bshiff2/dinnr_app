import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'profile.dart'; 
import 'chatPage.dart';

void main() {
  runApp(const FigmaToCodeApp());
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
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

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeKeyboardDown(),
        '/chat': (context) => ChatOngoing(),
        '/profile': (context) => Profile(),
      },
    );
  }
}

class HomeKeyboardDown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF121212)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('lib/assets/gradient/Gradients.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 80,
              child: Center(
                child: Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 400),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 10,
                            children: [
                              SizedBox(
                                width: 353,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 400),
                                  child: Text(
                                    'Tell us what you\'re hungry for...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontFamily: 'Arvo',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 119,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildChip('I\'m hungry for a pizza'),
                            _buildChip('I want Chinese food'),
                            _buildChip('Give me something fast and easy'),
                            _buildChip('I want to sit down'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 67,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 500),
                            child: Container(
                              width: double.infinity,
                              height: 67,
                              decoration: ShapeDecoration(
                                color: const Color(0xCC222222),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.home,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, '/chat');
                                    },
                                    icon: Icon(
                                      Icons.chat_bubble,
                                      color: Colors.white38,
                                      size: 28,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, '/profile');
                                    },
                                    icon: Icon(
                                      Icons.person,
                                      color: Colors.white38,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      debugShowCheckedModeBanner: false,
      title: 'Dinnr',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.auth});

  final FirebaseAuth? auth;

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    return StreamBuilder<User?>(
      stream: firebaseAuth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomePage(user: snapshot.data!, auth: firebaseAuth);
        }

        return LoginPage(auth: firebaseAuth);
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, this.auth});

  final User user;
  final FirebaseAuth? auth;

  FirebaseAuth get _auth => auth ?? FirebaseAuth.instance;

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dinnr'),
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fastfood, size: 72),
            const SizedBox(height: 16),
            Text('Hi ${user.email ?? user.uid}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('You are now signed in with Firebase Auth.'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: const Color(0xFF4B0040),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(68.28),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'SF Compact Rounded',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}