// Importing required packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/route_config/route_config.dart';
import 'package:wellness_app/service/auth_service.dart';

// ForgotPasswordScreen widget for sending password reset emails
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Form key for validating the email field
  final _formKey = GlobalKey<FormState>();

  // Controller for email input field
  final _emailController = TextEditingController();

  // State variable for loading state
  bool _isLoading = false;

  // Instance of AuthService for authentication operations
  final AuthService _authService = AuthService();

  // Regular expression for email validation
  final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Method to handle password reset
  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show centered loading indicator
      });
      try {
        // Call AuthService to send password reset email
        await _authService.resetPassword(email: _emailController.text);
        // Show green success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent! Check your inbox.',
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
        // Navigate back to login screen
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
                  // Header text with responsive font size and theme styling
                  Text(
                    'Reset Your Password',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 28.sp, // Responsive font size
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 20.h), // Responsive spacing
                  // Instructional text
                  Text(
                    'Enter your email to receive a password reset link',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16.sp, // Responsive font size
                      fontFamily: 'Poppins',
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 60.h), // Responsive spacing
                  // Form for email input
                  Form(
                    key: _formKey,
                    child: TextFormField(
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
                  ),
                  SizedBox(height: 20.h), // Responsive spacing
                  // Reset Password button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword, // Disable button during loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary, // Use theme secondary color
                      minimumSize: Size(double.infinity, 50.h), // Responsive height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r), // Responsive radius
                      ),
                    ),
                    child: Text(
                      'Reset Password',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16.sp, // Responsive font size
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h), // Responsive spacing
                  // Back to login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RoutesName.loginScreen);
                    },
                    child: Text(
                      'Back to Login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp, // Responsive font size
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
    // Dispose controller to prevent memory leaks
    _emailController.dispose();
    super.dispose();
  }
}