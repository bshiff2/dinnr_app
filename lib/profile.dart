import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatPage.dart';
import 'home_page.dart';

// Temporary main() for standalone testing - remove when integrating with main.dart
void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      initialRoute: '/profile',
      routes: {
        '/home': (context) => HomePageUI(),
        '/chat': (context) => ChatOngoing(),
        '/profile': (context) => Profile(),
      },
    );
  }
}

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/gradient/Gradients.png',
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Text(
                'You are not signed in. Please log in to view your profile.',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Material(
        color: const Color(0xFF121212),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: const Color(0xFF121212)),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'lib/assets/gradient/Gradients.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Main Content Area
              Positioned(
                left: 0,
                top: 20,
                right: 0,
                bottom: 0,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            // Profile Header - Centered
                            Positioned(
                              left: 20,
                              right: 20,
                              top: 29.99,
                              child: Column(
                                children: [
                                  // Profile picture
                                  Container(
                                    width: 100,
                                    height: 100,
                                    padding: const EdgeInsets.all(3),
                                    decoration: ShapeDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment(0.50, 0.00),
                                        end: Alignment(0.50, 1.00),
                                        colors: [const Color(0xFF74004A), const Color(0xFF197400)],
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    child: Container(
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF121212),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(Icons.person, color: Colors.white54, size: 40),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Name
                                  Text(
                                    'John Doe',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'SF Compact Rounded',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // Email
                                  Text(
                                    'john.doe@email.com',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFFA0A0A0),
                                      fontSize: 14,
                                      fontFamily: 'SF Compact Rounded',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stats Row
                            Positioned(
                              left: 20,
                              right: 20,
                              top: 220.35,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatCard('47', 'Orders'),
                                  _buildStatCard('12', 'Favorites'),
                                  _buildStatCard('8', 'Reviews'),
                                ],
                              ),
                            ),
                            // Menu Items
                            Positioned(
                              left: 20,
                              top: 317.77,
                              right: 20,
                              child: Column(
                                children: [
                                  _buildMenuItem('Favorite Places'),
                                  const SizedBox(height: 10),
                                  _buildMenuItem('Order History'),
                                  const SizedBox(height: 10),
                                  _buildMenuItem('Saved Addresses'),
                                  const SizedBox(height: 10),
                                  _buildMenuItem('Notifications'),
                                  const SizedBox(height: 10),
                                  _buildMenuItem('Settings'),
                                ],
                              ),
                            ),
                            // Log Out Button
                            Positioned(
                              left: 20,
                              right: 20,
                              bottom: 20,
                              child: Container(
                                height: 49.99,
                                decoration: ShapeDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(0.00, 0.50),
                                    end: Alignment(1.00, 0.50),
                                    colors: [const Color(0x4C4C0041), const Color(0x4C4C0041)],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'SF Compact Rounded',
                                        fontWeight: FontWeight.w400,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 111.22,
      height: 72.43,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.00, 0.50),
          end: Alignment(1.00, 0.50),
          colors: [const Color(0x7F4C0041), const Color(0x7F4C0041)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'SF Compact Rounded',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD4D4D4),
              fontSize: 12,
              fontFamily: 'SF Compact Rounded',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return Container(
      width: double.infinity,
      height: 49.99,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.00, 0.50),
          end: Alignment(1.00, 0.50),
          colors: [const Color(0xFF4C0041), const Color(0xFF4C0041)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              child: Icon(Icons.star, color: Colors.white54, size: 18),
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'SF Compact Rounded',
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}