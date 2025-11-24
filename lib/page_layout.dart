import 'package:flutter/material.dart';

class PageLayout extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const PageLayout({
    Key? key,
    required this.child,
    this.backgroundColor = const Color(0xFF121212), // Default background color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Content layer with reserved space for navbar
          Column(
            children: [
              Expanded(
                child: child,
              ),
              SizedBox(height: 90), // Reserve space for the navbar
            ],
          ),
        ],
      ),
    );
  }
}