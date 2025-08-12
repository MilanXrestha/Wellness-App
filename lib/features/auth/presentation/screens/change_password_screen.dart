import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For subtle animations
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart'; // Assuming you have a route for password reset

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

  // Password strength level (0: weak, 1: medium, 2: strong)
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _initializeUserState();
    _newPasswordController.addListener(_updatePasswordStrength);
  }

  Future<void> _initializeUserState() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final providerData = user.providerData;
      _isGoogleUser = providerData.any((info) => info.providerId == 'google.com');
      if (_isGoogleUser) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _hasPasswordSet = prefs.getBool('has_password_set_${user.uid}') ?? false;
        });
      }
    }
  }

  void _updatePasswordStrength() {
    final password = _newPasswordController.text;
    if (password.isEmpty) {
      setState(() => _passwordStrength = 0);
      return;
    }
    int strength = 0;
    if (password.length >= 8) strength++;
    if (_passwordRegExp.hasMatch(password)) strength++;
    setState(() => _passwordStrength = strength);
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
      await Future.delayed(const Duration(milliseconds: 500)); // Basic anti-brute force delay
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

        // Show success dialog
        _showSuccessDialog();
      } catch (e) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains('requires-recent-login') && _isGoogleUser && !_hasPasswordSet) {
          try {
            await _authService.reAuthenticateWithGoogle();
            await _authService.updatePassword(_newPasswordController.text);
            await _setPasswordFlag();
            _showSuccessDialog();
          } catch (reAuthError) {
            errorMessage = reAuthError.toString().replaceFirst('Exception: ', '');
          }
        }
        _showSnackBar(errorMessage, Colors.red);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        content: Text(
          'Password changed successfully!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16.sp),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close the screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  InputDecoration _getInputDecoration(String labelText, String hintText, bool isDarkMode, bool isPasswordVisible, VoidCallback onToggleVisibility) {
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
            'assets/icons/svg/ic_lock.svg',
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
          onTap: onToggleVisibility,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: SvgPicture.asset(
              isPasswordVisible
                  ? 'assets/icons/svg/ic_hide.svg'
                  : 'assets/icons/svg/ic_show.svg',
              colorFilter: const ColorFilter.mode(
                Colors.grey,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto, // Moves label up when focused
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
                                  'Change Password',
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
                        // Instructional text with tooltip for requirements
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
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
                            ),
                            SizedBox(width: 8.w),
                            Tooltip(
                              message: 'Password must be at least 8 characters, with uppercase, \n lowercase, number, and special character.',
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                        // Form for password inputs with animations
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Show Current Password field for Email/Password users or Google users with a password
                              if (!_isGoogleUser || (_isGoogleUser && _hasPasswordSet))
                                Animate(
                                  effects: const [FadeEffect(duration: Duration(milliseconds: 300))],
                                  child: TextFormField(
                                    controller: _currentPasswordController,
                                    obscureText: !_isCurrentPasswordVisible,
                                    decoration: _getInputDecoration(
                                      'Current Password',
                                      'Enter current password',
                                      isDarkMode,
                                      _isCurrentPasswordVisible,
                                          () => setState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
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
                                ),
                              if (!_isGoogleUser || (_isGoogleUser && _hasPasswordSet))
                                SizedBox(height: 20.h),
                              // Password Strength Indicator (above new password, shown only if text is entered)
                              if (_newPasswordController.text.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LinearProgressIndicator(
                                      value: _passwordStrength / 2, // 0 to 1 scale
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _passwordStrength == 0 ? Colors.red : _passwordStrength == 1 ? Colors.orange : Colors.green,
                                      ),
                                      minHeight: 4.h,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _passwordStrength == 0 ? 'Weak' : _passwordStrength == 1 ? 'Medium' : 'Strong',
                                      style: TextStyle(
                                        color: _passwordStrength == 0 ? Colors.red : _passwordStrength == 1 ? Colors.orange : Colors.green,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              Animate(
                                effects: const [FadeEffect(duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 100))],
                                child: TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: !_isNewPasswordVisible,
                                  decoration: _getInputDecoration(
                                    'New Password',
                                    'Enter new password',
                                    isDarkMode,
                                    _isNewPasswordVisible,
                                        () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
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
                              ),
                              SizedBox(height: 20.h),
                              Animate(
                                effects: const [FadeEffect(duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 200))],
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_isConfirmPasswordVisible,
                                  decoration: _getInputDecoration(
                                    'Confirm New Password',
                                    'Confirm new password',
                                    isDarkMode,
                                    _isConfirmPasswordVisible,
                                        () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
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
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Forgot Password Link
                        if (!_isGoogleUser || (_isGoogleUser && _hasPasswordSet))
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Navigate to password reset screen (adjust route)
                                Navigator.pushNamed(context, RoutesName.forgotPasswordScreen);
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppColors.primary, fontSize: 14.sp),
                              ),
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
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}