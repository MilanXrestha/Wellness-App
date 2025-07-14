import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/route_config/route_config.dart';
import 'package:wellness_app/service/auth_service.dart';

// SignUpScreenScreen widget for user registration with Email/Password and Google
class SignUpScreenScreen extends StatefulWidget {
  const SignUpScreenScreen({super.key});

  @override
  State<SignUpScreenScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreenScreen> {
  // Form key for validating the form fields
  final _formKey = GlobalKey<FormState>();
  // Controllers for input fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // State variables for UI interactions
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _rememberMe = false;
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

  // Method to handle sign-up with email and password
  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show centered loading indicator
      });
      try {
        // Call AuthService to sign up the user
        await _authService.signUpWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
        );
        // Show green success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful! Please log in.',
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
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
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
              'Google Sign-Up successful!',
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
              'Google Sign-Up canceled',
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Access ThemeData for consistent styling
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 100.h,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header text with responsive font size and theme styling
                  Text(
                    'Start your wellness journey today.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 60.h),
                  // Form for input fields
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name input field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: theme.inputDecorationTheme.filled,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            prefixIcon: SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: SvgPicture.asset(
                                  'assets/images/svg/ic_user.svg',
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
                              return 'Name is required';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters long';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),
                        // Email input field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: theme.inputDecorationTheme.filled,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            prefixIcon: SizedBox(
                              width: 48.w,
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
                        SizedBox(height: 20.h),
                        // Password input field
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
                              width: 48.w,
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
                              width: 48.w,
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
                        SizedBox(height: 20.h),
                        // Confirm Password input field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Confirm your password',
                            hintStyle: theme.inputDecorationTheme.hintStyle,
                            filled: theme.inputDecorationTheme.filled,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: theme.inputDecorationTheme.border,
                            prefixIcon: SizedBox(
                              width: 48.w,
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
                              width: 48.w,
                              height: 48.h,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: SvgPicture.asset(
                                    _isConfirmPasswordVisible
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
                              return 'Confirm Password is required';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // Remember me checkbox
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
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Sign Up button with Email/Password
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp, // Disable button during loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16.sp,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Divider for alternative sign-up options
                  Text(
                    'Or',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Google Sign-In button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn, // Disable button during loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: SvgPicture.asset(
                            'assets/images/svg/ic_google.svg',
                            width: 24.w,
                            height: 24.h,
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        Text(
                          'Sign Up with Google',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16.sp,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Link to login screen
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        RoutesName.loginScreen,
                      );
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}