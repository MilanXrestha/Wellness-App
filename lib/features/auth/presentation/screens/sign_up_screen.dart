import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart'; // Added for Lottie animation
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/auth/domain/auth_validator.dart';
import 'package:wellness_app/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:wellness_app/features/auth/presentation/widgets/auth_logo.dart';
import 'package:wellness_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:wellness_app/generated/app_localizations.dart';

/// A stateful widget for the sign-up screen, handling user registration with Email/Password and Google.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _rememberMe = false;
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
    if (savedEmail != null) {
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

  /// Handles email and password sign-up.
  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isLoading = true);
      try {
        final user = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );
        if (user != null && mounted) {
          await _saveEmail(_emailController.text);
          await _updateLastLoginTimestamp();
          final hasCompletedPreferences = await _authService
              .hasCompletedPreferences(user.uid);
          final navigateTo = hasCompletedPreferences
              ? RoutesName.mainScreen
              : RoutesName.userPrefsScreen;
          CustomBottomSheet.show(
            context: context,
            message: l10n.signUpSuccess,
            isSuccess: true,
            onOkPressed: () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, navigateTo);
              }
            },
          );
        }
      } catch (e) {
        if (mounted) {
          CustomBottomSheet.show(
            context: context,
            message: e.toString().replaceFirst('Exception: ', ''),
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
      if (user != null && mounted) {
        await _saveEmail(user.email ?? '');
        await _updateLastLoginTimestamp();
        final hasCompletedPreferences = await _authService
            .hasCompletedPreferences(user.uid);
        final navigateTo = hasCompletedPreferences
            ? RoutesName.mainScreen
            : RoutesName.userPrefsScreen;
        CustomBottomSheet.show(
          context: context,
          message: l10n.googleSignInSuccess,
          isSuccess: true,
          onOkPressed: () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, navigateTo);
            }
          },
        );
      } else if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: l10n.googleSignInCanceled,
          isSuccess: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
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
    return Scaffold(body: _buildBody(context));
  }

  /// Builds the main body with gradient background and loading overlay.
  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );

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
                  child: Lottie.asset(
                    'assets/animations/loading_animation.json',
                    width: 150.w,
                    height: 150.h,
                    fit: BoxFit.contain,
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
          l10n.signUpWelcome,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Poppins',
            color: isDarkMode ? AppColors.primary : AppColors.colorPrimaryLight,
            fontWeight: FontWeight.w700,
            fontSize: 28.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.signUpSubtitle,
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

  /// Builds the form with name, email, password, confirm password, and options.
  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthTextField(
            controller: _nameController,
            labelText: l10n.signUpNameHint,
            iconPath: 'assets/icons/svg/ic_user.svg',
            validator: (value) => AuthValidator.validateName(value, l10n),
          ),
          SizedBox(height: 16.h),
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
            suffixIconBuilder: (isFocused) => GestureDetector(
              onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(
                  _isPasswordVisible
                      ? 'assets/icons/svg/ic_show.svg'
                      : 'assets/icons/svg/ic_hide.svg',
                  width: 21.w,
                  height: 21.h,
                  colorFilter: ColorFilter.mode(
                    isFocused
                        ? (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.primary
                        : AppColors.colorPrimaryLight) // green when focused
                        : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextHint), // gray when unfocused
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            validator: (value) => AuthValidator.validatePassword(value, l10n),
          ),


          SizedBox(height: 16.h),

          AuthTextField(
            controller: _confirmPasswordController,
            labelText: l10n.signUpConfirmPasswordHint,
            iconPath: 'assets/icons/svg/ic_lock.svg',
            obscureText: !_isConfirmPasswordVisible,
            suffixIconBuilder: (isFocused) => GestureDetector(
              onTap: () => setState(
                    () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(
                  _isConfirmPasswordVisible
                      ? 'assets/icons/svg/ic_show.svg'
                      : 'assets/icons/svg/ic_hide.svg',
                  width: 21.w,
                  height: 21.h,
                  colorFilter: ColorFilter.mode(
                    isFocused
                        ? (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.primary
                        : AppColors.colorPrimaryLight) // focused → green
                        : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextHint), // unfocused → gray
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            validator: (value) => AuthValidator.validateConfirmPassword(
              value,
              _passwordController.text,
              l10n,
            ),
          ),


          SizedBox(height: 12.h),
          _buildOptions(context),
          SizedBox(height: 20.h),
          AuthButtons(
            isLoading: _isLoading,
            onEmailPressed: _handleSignUp,
            onGooglePressed: _handleGoogleSignIn,
            emailButtonText: l10n.signUpButton,
            googleButtonText: l10n.signUpGoogleButton,
          ),
          SizedBox(height: 25.h),
          _buildLoginPrompt(context),
        ],
      ),
    );
  }

  /// Builds the "Remember Me" option.
  Widget _buildOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) => setState(() => _rememberMe = value ?? false),
          activeColor: isDarkMode
              ? AppColors.primary
              : AppColors.colorPrimaryLight,
          checkColor: isDarkMode
              ? AppColors.darkTextPrimary
              : AppColors.lightBackground,
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
    );
  }

  /// Builds the login prompt.
  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          Navigator.pushNamed(context, RoutesName.loginScreen);
        }
      },
      child: Column(
        children: [
          Text(
            l10n.signUpHaveAccount,
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
            l10n.signInButton,
            style: theme.textTheme.labelLarge?.copyWith(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              color: isDarkMode
                  ? AppColors.primary
                  : AppColors.colorPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}