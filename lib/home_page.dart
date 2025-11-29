import 'package:flutter/material.dart';
//Imports done for testing traversal. Once integrated with main.dart, remove page imports.
import 'chatPage.dart';
import 'profile.dart';
import 'discover.dart';

// Temporary main() for page testing - remove when done for integration w/ main.dart
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
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomePageUI(),
        //Testing traversal buttons.
        '/chat': (context) => ChatOngoing(),
        '/profile': (context) => Profile(),
        '/discover': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as DiscoverPageArguments?;
          return DiscoverPage(
            initialQuery: args?.initialQuery,
            initialCategoryIndex: args?.initialCategoryIndex,
          );
        },
      },
    );
  }
}

class HomePageUI extends StatelessWidget {
  HomePageUI({super.key});

  static const List<_HomeSearchOption> _searchOptions = [
    _HomeSearchOption(
      label: 'Show me nearby',
      categoryIndex: 0, // Nearby tab
    ),
    _HomeSearchOption(
      label: 'What\'s trending',
      categoryIndex: 1, // Trending tab
    ),
    _HomeSearchOption(
      label: 'Give me something fast and easy',
      categoryIndex: 3, // Quick bites tab
    ),
    _HomeSearchOption(
      label: 'Family-friendly spots',
      categoryIndex: 4, // Family tab
    ),
  ];

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
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 100), // shift content up so "or" sits above arrow
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 10,
                            children: [
                              SizedBox(
                                width: 350,
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
                          children: _searchOptions
                              .map((option) => _buildChip(context, option))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'or',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 40,
                          fontFamily: 'Arvo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 200,
              child: Center(
                child: Image.asset(
                  'lib/assets/icons/HomeArrow.png',
                  width: 100,
                  height: 150,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 110, // sits above navbar
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/chat', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF74004A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Arvo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Ask Dinnr!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, _HomeSearchOption option) {
    return GestureDetector(
      onTap: () => _handleChipTap(context, option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: ShapeDecoration(
          color: const Color(0xFF4B0040),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(68.28),
          ),
        ),
        child: Text(
          option.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'SF Compact Rounded',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _handleChipTap(BuildContext context, _HomeSearchOption option) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/discover',
      (route) => false,
      arguments: DiscoverPageArguments(
        initialQuery: option.query,
        initialCategoryIndex: option.categoryIndex,
      ),
    );
  }
}

class _HomeSearchOption {
  final String label;
  final String? query;
  final int? categoryIndex;

  const _HomeSearchOption({
    required this.label,
    this.query,
    this.categoryIndex,
  });
}
