import 'package:flutter/material.dart';
import 'main.dart'; 
import 'chatPage.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      initialRoute: '/profile',
      routes: {
        '/': (context) => HomeKeyboardDown(),
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
              bottom: 0,
              right: 0,
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
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, '/');
                                    },
                                    icon: Icon(
                                      Icons.home,
                                      color: Colors.white38,
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
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.person,
                                      color: Colors.white,
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
            Positioned(
              left: 0,
              top: 20,
              right: 0,
              bottom: 80,
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
                          Positioned(
                            left: 20,
                            top: 29.99,
                            child: Container(
                              width: 353.65,
                              height: 165.36,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 120,
                                    top: 115.01,
                                    child: Container(
                                      width: 149.87,
                                      height: 52.36,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        spacing: 4.99,
                                        children: [
                                          Container(
                                            width: 136.85,
                                            height: 28.76,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'John Doe',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontFamily: 'SF Compact Rounded',
                                                    fontWeight: FontWeight.w700,
              Positioned(
                left: 0,
                top: 20,
                child: Container(
                  width: 393.65,
                  height: 742.48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 722.70,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 20,
                              top: 29.99,
                              child: SizedBox(
                                width: 353.65,
                                height: 165.36,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 120,
                                      top: 115.01,
                                      child: SizedBox(
                                        width: 149.87,
                                        height: 52.36,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          spacing: 4.99,
                                          children: [
                                            SizedBox(
                                              width: 136.85,
                                              height: 28.76,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
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
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 149.87,
                                              height: 18.61,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
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
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 149.87,
                                            height: 18.61,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'john.doe@email.com',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: const Color(0xFFA0A0A0),
                                                    fontSize: 14,
                                                    fontFamily: 'SF Compact Rounded',
                                                    fontWeight: FontWeight.w400,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              top: 220.35,
                              child: SizedBox(
                                width: 353.65,
                                height: 72.43,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Container(
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
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 41.91,
                                              top: 11.99,
                                              child: SizedBox(
                                                width: 27.50,
                                                height: 28.76,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '47',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontFamily: 'SF Compact Rounded',
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 38.21,
                                              top: 45.74,
                                              child: SizedBox(
                                                width: 37.10,
                                                height: 14.70,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Orders',
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
                                              ),
                                            ),
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Container(
                                                width: 111.22,
                                                height: 72.43,
                                                decoration: ShapeDecoration(
                                                  color: Colors.white.withValues(alpha: 0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 126.82,
                                    top: 0,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      padding: const EdgeInsets.only(top: 3, left: 3, right: 3),
                                      decoration: ShapeDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment(0.50, 0.00),
                                          end: Alignment(0.50, 1.00),
                                          colors: [const Color(0xFF74004A), const Color(0xFF197400)],
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(21442500),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            height: 94.01,
                                            decoration: ShapeDecoration(
                                              color: const Color(0xFF121212),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(21442500),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 43.74,
                                              top: 11.99,
                                              child: SizedBox(
                                                width: 27.46,
                                                height: 28.76,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '12',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontFamily: 'SF Compact Rounded',
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 31.81,
                                              top: 45.74,
                                              child: SizedBox(
                                                width: 51.15,
                                                height: 14.70,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Favorites',
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
                                              ),
                                            ),
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Container(
                                                width: 111.22,
                                                height: 72.43,
                                                decoration: ShapeDecoration(
                                                  color: Colors.white.withValues(alpha: 0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(15),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 242.43,
                                      top: 0,
                                      child: Container(
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
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 48.33,
                                              top: 11.99,
                                              child: SizedBox(
                                                width: 14.57,
                                                height: 28.76,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '8',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontFamily: 'SF Compact Rounded',
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 34.29,
                                              top: 45.74,
                                              child: SizedBox(
                                                width: 45.74,
                                                height: 14.70,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Reviews',
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
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration: BoxDecoration(),
                                                  child: Stack(),
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
                          Positioned(
                            left: 20,
                            top: 220.35,
                            child: Container(
                              width: 353.65,
                              height: 72.43,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Container(
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
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 41.91,
                                            top: 11.99,
                                            child: Text(
                                              '47',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontFamily: 'SF Compact Rounded',
                                                fontWeight: FontWeight.w700,
                            Positioned(
                              left: 20,
                              top: 317.77,
                              child: SizedBox(
                                width: 353.65,
                                height: 289.95,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Container(
                                        width: 353.65,
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
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 20,
                                              top: 15,
                                              child: SizedBox(
                                                width: 139.31,
                                                height: 20,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  spacing: 15,
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      clipBehavior: Clip.antiAlias,
                                                      decoration: BoxDecoration(),
                                                      child: Stack(),
                                                    ),
                                                    SizedBox(
                                                      width: 104.31,
                                                      height: 19.17,
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Favorite Places',
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
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 321.66,
                                              top: 19,
                                              child: Container(
                                                width: 11.99,
                                                height: 11.99,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ),
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Container(
                                                width: 353.65,
                                                height: 49.99,
                                                decoration: ShapeDecoration(
                                                  color: Colors.white.withValues(alpha: 0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 59.99,
                                      child: Container(
                                        width: 353.65,
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
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 20,
                                              top: 15,
                                              child: SizedBox(
                                                width: 132.30,
                                                height: 20,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  spacing: 15,
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      clipBehavior: Clip.antiAlias,
                                                      decoration: BoxDecoration(),
                                                      child: Stack(),
                                                    ),
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 19.17,
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Order History',
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
                                            ),
                                            Positioned(
                                              left: 321.66,
                                              top: 19,
                                              child: Container(
                                                width: 11.99,
                                                height: 11.99,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 38.21,
                                            top: 45.74,
                                            child: Text(
                                              'Orders',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: const Color(0xFFD4D4D4),
                                                fontSize: 12,
                                                fontFamily: 'SF Compact Rounded',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 121.22,
                                    top: 0,
                                    child: Container(
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
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 43.74,
                                            top: 11.99,
                                            child: Text(
                                              '12',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontFamily: 'SF Compact Rounded',
                                                fontWeight: FontWeight.w700,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 20,
                                              top: 15,
                                              child: SizedBox(
                                                width: 153.50,
                                                height: 20,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  spacing: 15,
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      clipBehavior: Clip.antiAlias,
                                                      decoration: BoxDecoration(),
                                                      child: Stack(),
                                                    ),
                                                    SizedBox(
                                                      width: 118.50,
                                                      height: 19.17,
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Saved Addresses',
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
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 321.66,
                                              top: 19,
                                              child: Container(
                                                width: 11.99,
                                                height: 11.99,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ),
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Container(
                                                width: 353.65,
                                                height: 49.99,
                                                decoration: ShapeDecoration(
                                                  color: Colors.white.withValues(alpha: 0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 179.97,
                                      child: Container(
                                        width: 353.65,
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
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 20,
                                              top: 15,
                                              child: SizedBox(
                                                width: 129.72,
                                                height: 20,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  spacing: 15,
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      clipBehavior: Clip.antiAlias,
                                                      decoration: BoxDecoration(),
                                                      child: Stack(),
                                                    ),
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 19.17,
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Notifications',
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
                                            ),
                                            Positioned(
                                              left: 321.66,
                                              top: 19,
                                              child: Container(
                                                width: 11.99,
                                                height: 11.99,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 31.81,
                                            top: 45.74,
                                            child: Text(
                                              'Favorites',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: const Color(0xFFD4D4D4),
                                                fontSize: 12,
                                                fontFamily: 'SF Compact Rounded',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 242.43,
                                    top: 0,
                                    child: Container(
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
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 48.33,
                                            top: 11.99,
                                            child: Text(
                                              '8',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontFamily: 'SF Compact Rounded',
                                                fontWeight: FontWeight.w700,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 20,
                                              top: 15,
                                              child: SizedBox(
                                                width: 95.36,
                                                height: 20,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  spacing: 15,
                                                  children: [
                                                    Container(
                                                      width: 20,
                                                      height: 20,
                                                      clipBehavior: Clip.antiAlias,
                                                      decoration: BoxDecoration(),
                                                      child: Stack(),
                                                    ),
                                                    Expanded(
                                                      child: SizedBox(
                                                        height: 20.17,
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Settings',
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
                                            ),
                                            Positioned(
                                              left: 321.66,
                                              top: 19,
                                              child: Container(
                                                width: 11.99,
                                                height: 11.99,
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Stack(),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 34.29,
                                            top: 45.74,
                                            child: Text(
                                              'Reviews',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: const Color(0xFFD4D4D4),
                                                fontSize: 12,
                                                fontFamily: 'SF Compact Rounded',
                                                fontWeight: FontWeight.w400,
                                              ),
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
                          Positioned(
                            left: 20,
                            bottom: 20,
                            right: 20,
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 9.99,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(),
                                      child: Stack(),
                                    ),
                                    SizedBox(
                                      width: 57.50,
                                      height: 20.17,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
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
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(),
                                  ),
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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(),
              child: Stack(),
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
            Container(
              width: 11.99,
              height: 11.99,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(),
              child: Stack(),
            ),
          ],
        ),
      ),
    );
  }
}