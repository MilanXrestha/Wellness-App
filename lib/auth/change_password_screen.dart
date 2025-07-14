import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/service/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleUser = false;
  bool _hasPasswordSet = false; // Tracks if Google user has set a password
  final AuthService _authService = AuthService();
  final _passwordRegExp = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  @override
  void initState() {
    super.initState();
    _initializeUserState();
  }

  Future<void> _initializeUserState() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final providerData = user.providerData;
      _isGoogleUser = providerData.any((info) => info.providerId == 'google.com');
      if (_isGoogleUser) {
        // Check SharedPreferences for password status
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _hasPasswordSet = prefs.getBool('has_password_set_${user.uid}') ?? false;
        });
      }
    }
  }

  Future<void> _setPasswordFlag() async {
    final user = _authService.getCurrentUser();
    if (user != null && _isGoogleUser) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_password_set_${user.uid}', true);
      setState(() {
        _hasPasswordSet = true;
      });
    }
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = _authService.getCurrentUser();
        if (user == null) {
          throw Exception('No user is signed in.');
        }

        // Re-authenticate for Email/Password users or Google users with a password
        if (!_isGoogleUser || (_isGoogleUser && _hasPasswordSet)) {
          await _authService.reAuthenticate(
            email: user.email!,
            password: _currentPasswordController.text,
          );
        }

        // Update password
        await _authService.updatePassword(_newPasswordController.text);

        // If Google user, mark that a password has been set
        if (_isGoogleUser) {
          await _setPasswordFlag();
        }

        // Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password changed successfully!',
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
        Navigator.pop(context);
      } catch (e) {
        if (e.toString().contains('requires-recent-login') && _isGoogleUser && !_hasPasswordSet) {
          try {
            await _authService.reAuthenticateWithGoogle();
            await _authService.updatePassword(_newPasswordController.text);
            await _setPasswordFlag();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Password changed successfully!',
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
            Navigator.pop(context);
          } catch (reAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  reAuthError.toString().replaceFirst('Exception: ', ''),
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
        } else {
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
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 20.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // iOS-style Navigation Bar
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios, // iOS-style back button
                            color: theme.iconTheme.color,
                            size: 22.w,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Change Password', // App title
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25.h),
                    // Instructional text
                    Text(
                      _isGoogleUser && !_hasPasswordSet
                          ? 'Set a new password below'
                          : 'Enter your current and new password below',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16.sp,
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),
                    // Form for password inputs
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Show Current Password field for Email/Password users or Google users with a password
                          if (!_isGoogleUser || (_isGoogleUser && _hasPasswordSet))
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: !_isCurrentPasswordVisible,
                              decoration: InputDecoration(
                                hintText: 'Current Password',
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
                                        _isCurrentPasswordVisible =
                                        !_isCurrentPasswordVisible;
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(12.w),
                                      child: SvgPicture.asset(
                                        _isCurrentPasswordVisible
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
                                  return 'Current Password is required';
                                }
                                return null;
                              },
                            ),
                          if (!_isGoogleUser || (_isGoogleUser && _hasPasswordSet))
                            SizedBox(height: 20.h),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: !_isNewPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'New Password',
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
                                      _isNewPasswordVisible = !_isNewPasswordVisible;
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: SvgPicture.asset(
                                      _isNewPasswordVisible
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
                                return 'New Password is required';
                              }
                              if (!_passwordRegExp.hasMatch(value)) {
                                return 'Password must be at least 8 characters long\nand include uppercase, lowercase, number, and special character';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20.h),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Confirm New Password',
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
                                      _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
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
                                return 'Confirm New Password is required';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        'Update Password',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}