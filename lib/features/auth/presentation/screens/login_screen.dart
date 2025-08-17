import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/auth/domain/auth_validator.dart';
import 'package:wellness_app/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:wellness_app/features/auth/presentation/widgets/auth_logo.dart';
import 'package:wellness_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'dart:developer'; // Add for logging

/// A stateful widget for the login screen, handling user authentication with Email/Password and Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  /// Loads saved email from SharedPreferences if "Remember Me" is enabled.
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null && mounted) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  /// Saves email to SharedPreferences if "Remember Me" is checked, or removes it.
  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', email.trim());
    } else {
      await prefs.remove('remembered_email');
    }
  }

  /// Updates the last login timestamp in SharedPreferences.
  Future<void> _updateLastLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_login_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Maps FirebaseAuthException to user-friendly error messages.
  String _mapEmailErrorToMessage(FirebaseAuthException e, AppLocalizations l10n) {
    switch (e.code) {
      case 'user-not-found':
        return l10n.userNotFound;
      case 'wrong-password':
        return l10n.wrongPassword;
      case 'invalid-email':
        return l10n.invalidEmail;
      case 'user-disabled':
        return l10n.userDisabled;
      default:
        return l10n.genericError;
    }
  }

  /// Maps FirebaseAuthException for Google Sign-In to user-friendly error messages.
  String _mapGoogleErrorToMessage(FirebaseAuthException e, AppLocalizations l10n) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return l10n.accountExistsWithDifferentCredential;
      case 'invalid-credential':
        return l10n.invalidCredential;
      default:
        return l10n.genericError;
    }
  }

  /// Handles email and password login.
  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isLoading = true);
      try {
        final user = await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;
        if (user != null) {
          await _saveEmail(_emailController.text);
          await _updateLastLoginTimestamp();
          final navigateTo = await _authService.getUserNavigationRoute(user.uid);
          log('Email login successful for user ${user.uid}, navigating to $navigateTo');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.loginSuccess,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 2500)); // Increased to 2.5s
          if (mounted) {
            Navigator.pushReplacementNamed(context, navigateTo);
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          CustomBottomSheet.show(
            context: context,
            message: _mapEmailErrorToMessage(e, l10n),
            isSuccess: false,
          );
        }
      } catch (e) {
        log('Unexpected error during email login: $e');
        if (mounted) {
          CustomBottomSheet.show(
            context: context,
            message: l10n.genericError,
            isSuccess: false,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Handles Google Sign-In.
  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        await _saveEmail(user.email ?? '');
        await _updateLastLoginTimestamp();
        final navigateTo = await _authService.getUserNavigationRoute(user.uid);
        log('Google login successful for user ${user.uid}, navigating to $navigateTo');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.googleSignInSuccess,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 2500)); // Increased to 2.5s
        if (mounted) {
          Navigator.pushReplacementNamed(context, navigateTo);
        }
      } else {
        CustomBottomSheet.show(
          context: context,
          message: l10n.googleSignInCanceled,
          isSuccess: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: _mapGoogleErrorToMessage(e, l10n),
          isSuccess: false,
        );
      }
    } catch (e) {
      log('Unexpected error during Google login: $e');
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: l10n.genericError,
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await CustomAlertDialog.show(
          context: context,
          title: l10n.exitAppTitle,
          message: l10n.exitAppMessage,
          cancelText: l10n.cancel,
          confirmText: l10n.exit,
        );
        return shouldExit;
      },
      child: Scaffold(body: _buildBody(context)),
    );
  }

  /// Builds the main body with gradient background and loading overlay.
  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AuthLogo(),
                    _buildWelcomeText(context),
                    _buildForm(context),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: AppColors.overlay,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 4.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the welcome text and subtitle.
  Widget _buildWelcomeText(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        SizedBox(height: 10.h),
        Text(
          l10n.loginWelcome,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Poppins',
            color: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 28.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.loginSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  /// Builds the form with email, password, and options.
  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthTextField(
            controller: _emailController,
            labelText: l10n.loginEmailHint,
            iconPath: 'assets/icons/svg/ic_mail.svg',
            keyboardType: TextInputType.emailAddress,
            validator: (value) => AuthValidator.validateEmail(value, l10n),
          ),
          SizedBox(height: 16.h),
          AuthTextField(
            controller: _passwordController,
            labelText: l10n.loginPasswordHint,
            iconPath: 'assets/icons/svg/ic_lock.svg',
            obscureText: !_isPasswordVisible,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(
                  _isPasswordVisible ? 'assets/icons/svg/ic_hide.svg' : 'assets/icons/svg/ic_show.svg',
                  width: 21.w,
                  height: 21.h,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            validator: (value) => AuthValidator.validatePassword(value, l10n),
          ),
          SizedBox(height: 12.h),
          _buildOptions(context),
          SizedBox(height: 20.h),
          AuthButtons(
            isLoading: _isLoading,
            onEmailPressed: _handleEmailLogin,
            onGooglePressed: _handleGoogleSignIn,
            emailButtonText: l10n.loginButton,
            googleButtonText: l10n.loginGoogleButton,
          ),
          SizedBox(height: 25.h),
          _buildSignUpPrompt(context),
        ],
      ),
    );
  }

  /// Builds the "Remember Me" and "Forgot Password" options.
  Widget _buildOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) => setState(() => _rememberMe = value ?? false),
              activeColor: isDarkMode ? AppColors.primary : AppColors.lightSecondary,
              checkColor: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightBackground,
            ),
            Text(
              l10n.loginRememberMe,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            if (mounted) {
              Navigator.pushNamed(context, RoutesName.forgotPasswordScreen);
            }
          },
          child: Text(
            l10n.loginForgotPassword,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              color: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the sign-up prompt.
  Widget _buildSignUpPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          Navigator.pushNamed(context, RoutesName.signUpScreen);
        }
      },
      child: Column(
        children: [
          Text(
            l10n.loginSignUpPrompt,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 14.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.signUpLoginLink,
            style: theme.textTheme.labelLarge?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              color: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}