import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF1a4d2e), // Dark green
                Color(0xFF000000), // Black
                Color(0xFF4a0e4e), // Deep purple/magenta
              ],
              stops: [0.0, 0.5, 1.0], // Smooth transition
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tell us what you\'re hungry for...',
                  style: GoogleFonts.libreBaskerville(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        'Pizza',
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    Chip(
                      label: Text(
                        'Sushi',
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    Chip(
                      label: Text(
                        'Burgers',
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    Chip(
                      label: Text(
                        'Salads',
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    Chip(
                      label: Text(
                        'Desserts',
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.pink.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}