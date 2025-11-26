import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chatPage.dart';
import 'profile.dart';
import 'discover.dart';

class NavBar extends StatelessWidget {
  final Widget child;

  const NavBar({Key? key, required this.child}) : super(key: key);

  int _getSelectedIndex(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    switch (currentRoute) {
      case '/home':
        return 0;
      case '/discover':
        return 1;
      case '/chat':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }

  void _navigateTo(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => NavBar(
            child: _getPageForRoute(route),
          ),
          settings: RouteSettings(name: route), // Explicitly set route name
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child; // No transition effect
          },
        ),
        (route) => false,
      );
    }
  }

  Widget _getPageForRoute(String route) {
    switch (route) {
      case '/home':
        return HomePageUI();
      case '/discover':
        return DiscoverPage();
      case '/chat':
        return ChatOngoing();
      case '/profile':
        return Profile();
      default:
        return HomePageUI();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents navbar from moving with the keyboard
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212), // Ensure background color extends fully
            ),
            child: child,
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0, // Further decreased bottom value to move the navbar lower
            child: SafeArea( // Wrap BottomNavigationBar in SafeArea to avoid overflow
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Rounded corners
                child: SizedBox(
                  height: 70, // Increased height to show labels
                  child: BottomNavigationBar(
                    currentIndex: _getSelectedIndex(context),
                    backgroundColor: const Color(0xCC222222),
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.explore),
                        label: 'Discover',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat_bubble),
                        label: 'Chat',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                    onTap: (index) {
                      switch (index) {
                        case 0:
                          _navigateTo(context, '/home');
                          break;
                        case 1:
                          _navigateTo(context, '/discover');
                          break;
                        case 2:
                          _navigateTo(context, '/chat');
                          break;
                        case 3:
                          _navigateTo(context, '/profile');
                          break;
                      }
                    },
                    type: BottomNavigationBarType.fixed, // Ensures no shifting animation
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
