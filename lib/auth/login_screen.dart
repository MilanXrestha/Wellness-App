// Importing required packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/route_config/route_config.dart';
import 'package:wellness_app/service/auth_service.dart';

// LoginScreen widget for user login with Email/Password and Google
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validating the form fields
  final _formKey = GlobalKey<FormState>();

  // Controllers for email and password input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables for UI interactions
  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Tracks loading state for authentication

  // Instance of AuthService for authentication operations
  final AuthService _authService = AuthService();

  // Regular expression for email validation
  final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Regular expression for password validation
  // Requires: at least one uppercase, one lowercase, one number, one special character, min 8 chars
  final _passwordRegExp = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  // Method to handle Email/Password login
  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show centered loading indicator
      });
      try {
        // Call AuthService to sign in with email and password
        final user = await _authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (user != null) {
          // Show green success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login successful!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          // Navigate to user preferences screen
          Navigator.pushReplacementNamed(context, RoutesName.userPrefsScreen);
        }
      } catch (e) {
        // Show red error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  // Method to handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true; // Show centered loading indicator
    });
    try {
      // Call AuthService to sign in with Google
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        // Show green success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Sign-In successful!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        // Navigate to user preferences screen
        Navigator.pushReplacementNamed(context, RoutesName.userPrefsScreen);
      } else {
        // Show red cancellation SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Sign-In canceled',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show red error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for consistent status bar appearance
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Access ThemeData for consistent styling
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background color
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w, // Responsive horizontal padding
                vertical: 100.h, // Responsive vertical padding
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome text with responsive font size and theme styling
                  Text(
                    'Welcome back!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 28.sp, // Responsive font size
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 60.h), // Responsive spacing
                  // Form for email and password input
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email input field with validation and theme styling
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: theme.inputDecorationTheme.filled,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            prefixIcon: SizedBox(
                              width: 48.w, // Responsive icon size
                              height: 48.h,
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: SvgPicture.asset(
                                  'assets/images/svg/ic_mail.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!_emailRegExp.hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h), // Responsive spacing
                        // Password input field with visibility toggle and validation
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: theme.inputDecorationTheme.filled,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            prefixIcon: SizedBox(
                              width: 48.w, // Responsive icon size
                              height: 48.h,
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: SvgPicture.asset(
                                  'assets/images/svg/ic_lock.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            suffixIcon: SizedBox(
                              width: 48.w, // Responsive icon size
                              height: 48.h,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: SvgPicture.asset(
                                    _isPasswordVisible
                                        ? 'assets/images/svg/ic_hide.svg'
                                        : 'assets/images/svg/ic_show.svg',
                                    colorFilter: const ColorFilter.mode(
                                      Colors.grey,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (!_passwordRegExp.hasMatch(value)) {
                              return 'Password must be at least 8 characters long\nand include uppercase, lowercase, number, and special character';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h), // Responsive spacing
                  // Remember me checkbox and forgot password link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: Colors.white70,
                            checkColor: Colors.black,
                          ),
                          Text(
                            'Remember me',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp, // Responsive font size
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to Forgot Password screen
                          Navigator.pushNamed(context, RoutesName.forgotPasswordScreen);
                        },
                        child: Text(
                          'Forgot Password?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp, // Responsive font size
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h), // Responsive spacing
                  // Login button with Email/Password authentication
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailLogin, // Disable button during loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary, // Use theme secondary color
                      minimumSize: Size(double.infinity, 50.h), // Responsive height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r), // Responsive radius
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16.sp, // Responsive font size
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h), // Responsive spacing
                  // Divider for alternative login options
                  Text(
                    'Or',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp, // Responsive font size
                    ),
                  ),
                  SizedBox(height: 20.h), // Responsive spacing
                  // Google sign-in button with authentication
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn, // Disable button during loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary, // Use theme secondary color
                      minimumSize: Size(double.infinity, 50.h), // Responsive height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r), // Responsive radius
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 4.w), // Responsive padding
                          child: SvgPicture.asset(
                            'assets/images/svg/ic_google.svg',
                            width: 24.w, // Responsive icon size
                            height: 24.h,
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Text(
                          'Sign in with Google',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16.sp, // Responsive font size
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h), // Responsive spacing
                  // Link to sign-up screen using named route
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RoutesName.signUpScreen);
                    },
                    child: Text(
                      'Don\'t have an account? Create an account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp, // Responsive font size
                      ),
                    ),
                  ),





                  //Admin dashboard Button
                  SizedBox(height: 90.h), // Add spacing between the two buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RoutesName.adminDashboardScreen);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary, // Customize as needed
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Admin Dashboard',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16.sp,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),







                ],
              ),
            ),
          ),
          // Show full-screen loading overlay with a single centered CircularProgressIndicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3), // Semi-transparent background like Google's
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4.w, // Responsive thickness
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.secondary, // Match theme color
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}