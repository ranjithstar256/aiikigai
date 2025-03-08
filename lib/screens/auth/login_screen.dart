import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/analytics_service.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();

    // Log screen view
    ref.read(analyticsServiceProvider).logScreenView('login_screen');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    try {
      // Sign in with email and password
      await ref.read(authProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Log login event
      ref.read(analyticsServiceProvider).logLogin('email');

      // Navigate to home screen
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Sign in with Google
      await ref.read(authProvider.notifier).signInWithGoogle();

      // Log login event
      ref.read(analyticsServiceProvider).logLogin('google');

      // Navigate to home screen
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToSignUp() {
    context.push('/signup');
  }

  void _navigateToForgotPassword() {
    // TODO: Implement forgot password screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset link sent to your email'),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor,
                  theme.colorScheme.background,
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App logo/icon
                    Icon(
                      Icons.bubble_chart,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),

                    // App name
                    Text(
                      'Ikigai Journey',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Discover your purpose',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Login card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'Login',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: Validators.validateEmail,
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: Validators.validateSimplePassword,
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 8),

                              // Remember me and Forgot password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Remember me
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.9, // Slightly smaller checkbox
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: isLoading
                                              ? null
                                              : (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      Text(
                                        'Remember me',
                                        style: GoogleFonts.lato(
                                          fontSize: 13, // Slightly smaller font
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Forgot password
                                  Flexible(
                                    child: TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : _navigateToForgotPassword,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 8), // Reduced padding
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: GoogleFonts.lato(
                                          fontSize: 13, // Slightly smaller font
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Login button
                              ElevatedButton(
                                onPressed: isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  'Login',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Or divider
                              Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.lato(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Google login button
                              OutlinedButton.icon(
                                onPressed: isLoading ? null : _signInWithGoogle,
                                icon: Image.asset(
                                  'assets/images/google_logo.png',
                                  height: 24,
                                ),
                                label: Text(
                                  'Sign in with Google',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: theme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : _navigateToSignUp,
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Continue as guest
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/home'),
                      child: Text(
                        'Continue as Guest',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: theme.primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}