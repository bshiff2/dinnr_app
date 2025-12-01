import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Reset Password',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'SF Compact Rounded',
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA0A0A0),
                    fontFamily: 'SF Compact Rounded',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontFamily: 'SF Compact Rounded',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text(
                'Send Reset Link',
                style: TextStyle(
                  color: Color(0xFF74004A),
                  fontFamily: 'SF Compact Rounded',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await Auth().sendPasswordResetEmail(emailController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent. Please check your email.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'No account exists with this email address';
              break;
            case 'invalid-email':
              _errorMessage = 'Please enter a valid email address';
              break;
            default:
              _errorMessage = e.message ?? 'Failed to send reset email';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Basic validation
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter both email and password';
        });
        return;
      }

      await Auth().signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Navigate back to profile page after successful login
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception details:');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      
      setState(() {
        switch (e.code.toLowerCase()) {
          case 'too-many-requests':
            _errorMessage = 'Too many unsuccessful attempts. Please try again later.';
            break;
          case 'network-request-failed':
            _errorMessage = 'Network error. Please check your internet connection.';
            break;
          case 'user-disabled':
            _errorMessage = 'This account has been disabled. Please contact support.';
            break;
          default:
            // For most auth errors, just show a generic message
            _errorMessage = 'Invalid email or password.';
        }
      });
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
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
                      Icons.restaurant,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                    
                    const SizedBox(height: 30),
                    
                    const Text(
                      "Welcome Back!",
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
                      "Sign in to find the best restaurants.",
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
                    
                    const SizedBox(height: 24),
                    
                    // Sign in button
                    Container(
                      height: 50,
                      decoration: ShapeDecoration(
                        color: Color(0xFF74004A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _signIn,
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
                                    'Sign In',
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

                    const SizedBox(height: 12),
                    
                    // Forgot password button
                    TextButton(
                      onPressed: _isLoading ? null : () => _showForgotPasswordDialog(context),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFFA0A0A0),
                          fontSize: 14,
                          fontFamily: 'SF Compact Rounded',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sign up section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 14,
                            fontFamily: 'SF Compact Rounded',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            "Sign Up",
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