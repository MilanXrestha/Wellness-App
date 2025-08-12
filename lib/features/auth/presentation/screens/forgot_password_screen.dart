// Importing required packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For subtle animations
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/resources/colors.dart'; // Assuming AppColors is defined here
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await Future.delayed(const Duration(milliseconds: 500)); // Basic anti-brute force delay, matching Change Password
      try {
        await _authService.resetPassword(email: _emailController.text);
        _showSnackBar('Password reset email sent! Check your inbox.', Colors.green);
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      } catch (e) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        _showSnackBar(errorMessage, Colors.red);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
        backgroundColor: backgroundColor,
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

  InputDecoration _getInputDecoration(String labelText, String hintText, bool isDarkMode) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.grey),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey),
      filled: true,
      fillColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey, width: 1.w),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey, width: 1.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: isDarkMode ? AppColors.primary : Colors.black, width: 1.5.w),
      ),
      prefixIcon: SizedBox(
        width: 48.w,
        height: 48.h,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: SvgPicture.asset(
            'assets/icons/svg/ic_mail.svg',
            colorFilter: const ColorFilter.mode(
              Colors.grey,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: false,
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 64.h,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Container(
                        height: 56.h,
                        decoration: BoxDecoration(
                          gradient: isDarkMode
                              ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.grey[850]!, Colors.grey[900]!],
                          )
                              : null,
                          color: isDarkMode ? null : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: isDarkMode
                              ? []
                              : [
                            BoxShadow(
                              color: AppColors.lightTextPrimary.withOpacity(0.2),
                              blurRadius: 6.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios,
                                size: 24.sp,
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Back',
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Forgot Password',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 24.sp,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                onPressed: null, // Dummy for symmetry
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructional text with tooltip for email format
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Enter your email to receive a password reset link',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 16.sp,
                                  fontFamily: 'Poppins',
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Tooltip(
                              message: 'Enter a valid email address (e.g., example@domain.com).',
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                        // Form for email input with animation
                        Form(
                          key: _formKey,
                          child: Animate(
                            effects: const [FadeEffect(duration: Duration(milliseconds: 300))],
                            child: TextFormField(
                              controller: _emailController,
                              decoration: _getInputDecoration(
                                'Email',
                                'Enter your email',
                                isDarkMode,
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
                        ),
                        SizedBox(height: 20.h),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            minimumSize: Size(double.infinity, 50.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Reset Password',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 16.sp,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Back to login link
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, RoutesName.loginScreen);
                            },
                            child: Text(
                              'Back to Login',
                              style: TextStyle(color: AppColors.primary, fontSize: 14.sp),
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4.w,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.secondary,
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
    _emailController.dispose();
    super.dispose();
  }
}