import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'profile_setup.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Auth().createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        // Navigate to profile setup
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
        // After profile setup is complete, navigate to profile page and clear the stack
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/profile',
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'weak-password':
              _errorMessage = 'The password provided is too weak';
              break;
            case 'email-already-in-use':
              _errorMessage = 'An account already exists for this email';
              break;
            case 'invalid-email':
              _errorMessage = 'Invalid email address';
              break;
            case 'operation-not-allowed':
              _errorMessage = 'Email/password accounts are not enabled';
              break;
            default:
              _errorMessage = 'Failed to create account: ${e.message}';
          }
        } else {
          _errorMessage = 'An error occurred while creating your account';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/gradient/Gradients.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Food Icon
                  const Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                    
                    const SizedBox(height: 30),
                    
                    const Text(
                      "Find great restaurants!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontFamily: 'SF Compact Rounded',
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    const Text(
                      "Create an account to start finding the best places to eat!",
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 16,
                        fontFamily: 'SF Compact Rounded',
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),

                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontFamily: 'SF Compact Rounded',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (_errorMessage != null) const SizedBox(height: 20),
                    
                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'SF Compact Rounded',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontFamily: 'SF Compact Rounded',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF4C0041)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF74004A), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF4C0041).withOpacity(0.3),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !_isLoading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'SF Compact Rounded',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontFamily: 'SF Compact Rounded',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF4C0041)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF74004A), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF4C0041).withOpacity(0.3),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm Password field
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      enabled: !_isLoading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'SF Compact Rounded',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontFamily: 'SF Compact Rounded',
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF4C0041)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF74004A), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF4C0041).withOpacity(0.3),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign up button
                    Container(
                      height: 50,
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(0.00, 0.50),
                          end: Alignment(1.00, 0.50),
                          colors: [Color(0xFF74004A), Color(0xFF197400)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _signUp,
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'SF Compact Rounded',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sign in section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 14,
                            fontFamily: 'SF Compact Rounded',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Return to sign in screen
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'SF Compact Rounded',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}