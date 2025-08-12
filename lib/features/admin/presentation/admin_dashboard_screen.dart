import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:wellness_app/features/admin/presentation/manage_preferences_screen.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'manage_users_screen.dart';
import 'manage_categories_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _stats = {
    'Total Users': '0',
    'Total Preferences': '0',
    'Total Categories': '0',
    'Total Tips': '0',
    'Tips by Type': 'Quotes: 0, Tips: 0, Health Tips: 0',
  };
  List<String> _allUserIds = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestore.collection('users').get(),
        _firestore.collection('preferences').get(),
        _firestore.collection('categories').get(),
        _firestore.collection('tips').get(),
        _firestore.collection('tips').where('tipsType', isEqualTo: 'quote').get(),
        _firestore.collection('tips').where('tipsType', isEqualTo: 'tip').get(),
        _firestore.collection('tips').where('tipsType', isEqualTo: 'healthTips').get(),
      ]);

      if (mounted) {
        setState(() {
          _allUserIds = results[0].docs.map((doc) => doc.id).toList();
          _stats = {
            'Total Users': results[0].size.toString(),
            'Total Preferences': results[1].size.toString(),
            'Total Categories': results[2].size.toString(),
            'Total Tips': results[3].size.toString(),
            'Tips by Type': 'Quotes: ${results[4].size}, Tips: ${results[5].size}, Health Tips: ${results[6].size}',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: '${AppStrings.error} ${e.toString().replaceFirst('Exception: ', '')}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signOut();
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: AppStrings.signOutSuccess,
          isSuccess: true,
          onOkPressed: () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: '${AppStrings.error} ${e.toString().replaceFirst('Exception: ', '')}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showSignOutDialog() async {
    return CustomAlertDialog.show(
      context: context,
      title: AppStrings.signOut,
      message: AppStrings.signOutConfirmation,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.signOut,
      onConfirm: () {},
    );
  }

  void _showProfileMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100.w, 50.h, 10.w, 0),
      items: [
        PopupMenuItem(
          value: 'settings',
          child: Text(
            AppStrings.settings,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'sign_out',
          child: Text(
            AppStrings.signOut,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ).then((value) {
      if (value == 'sign_out' && mounted) {
        _handleSignOut();
      } else if (value == 'settings' && mounted) {
        Navigator.pushNamed(context, RoutesName.userPrefsScreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    Widget statCard({
      required String title,
      required String value,
      required IconData icon,
      VoidCallback? onTap,
      required int index,
    }) {
      return FadeInUp(
        duration: Duration(milliseconds: 500 + (index * 100)),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [AppColors.darkSurface.withAlpha(230), AppColors.darkSurface.withAlpha(200)]
                    : [AppColors.lightSurface.withAlpha(230), AppColors.lightSurface.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary.withAlpha(77), width: 1.w),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      FaIcon(
                        icon,
                        size: 28.sp,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextSecondary,
                      ),
                      SizedBox(width: 30.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.darkTextPrimary : theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              value,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: title == AppStrings.tipsByType ? 15.sp : 22.sp,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 20.sp,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextSecondary,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldSignOut = await _showSignOutDialog();
        if (shouldSignOut == true) {
          await _handleSignOut();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.primary,
                              size: 20.sp,
                            ),
                            onPressed: () async {
                              final shouldSignOut = await _showSignOutDialog();
                              if (shouldSignOut == true) {
                                await _handleSignOut();
                              }
                            },
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            AppStrings.adminDashboardTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.sp,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _showProfileMenu,
                            child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withAlpha(77), width: 1.w),
                              ),
                              child: CircleAvatar(
                                radius: 18.r,
                                backgroundColor: AppColors.primary.withAlpha(77),
                                backgroundImage: currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty
                                    ? NetworkImage(currentUser.photoURL!)
                                    : null,
                                child: currentUser?.photoURL == null || currentUser!.photoURL!.isEmpty
                                    ? Text(
                                  currentUser?.displayName?.isNotEmpty == true
                                      ? currentUser!.displayName![0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? AppColors.darkTextPrimary : Colors.white,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 6.w,
                        radius: Radius.circular(3.r),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.overview,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20.sp,
                                  color: isDarkMode ? AppColors.darkTextPrimary : theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              ListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  statCard(
                                    title: AppStrings.totalUsers,
                                    value: _stats['Total Users']!,
                                    icon: FontAwesomeIcons.users,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const ManageUsersScreen(),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(opacity: animation, child: child);
                                          },
                                          transitionDuration: const Duration(milliseconds: 300),
                                        ),
                                      );
                                    },
                                    index: 0,
                                  ),
                                  statCard(
                                    title: AppStrings.totalPreferences,
                                    value: _stats['Total Preferences']!,
                                    icon: FontAwesomeIcons.gears,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const ManagePreferencesScreen(),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(opacity: animation, child: child);
                                          },
                                          transitionDuration: const Duration(milliseconds: 300),
                                        ),
                                      );
                                    },
                                    index: 1,
                                  ),
                                  statCard(
                                    title: AppStrings.totalCategories,
                                    value: _stats['Total Categories']!,
                                    icon: FontAwesomeIcons.folderOpen,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const ManageCategoriesScreen(),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(opacity: animation, child: child);
                                          },
                                          transitionDuration: const Duration(milliseconds: 300),
                                        ),
                                      );
                                    },
                                    index: 2,
                                  ),
                                  statCard(
                                    title: AppStrings.totalTips,
                                    value: _stats['Total Tips']!,
                                    icon: FontAwesomeIcons.lightbulb,
                                    onTap: () => Navigator.pushNamed(context, RoutesName.manageTipsScreen),
                                    index: 3,
                                  ),
                                  statCard(
                                    title: AppStrings.tipsByType,
                                    value: _stats['Tips by Type']!,
                                    icon: FontAwesomeIcons.list,
                                    onTap: null,
                                    index: 4,
                                  ),
                                  statCard(
                                    title: 'Send Notifications',
                                    value: 'Notify All Users',
                                    icon: FontAwesomeIcons.solidPaperPlane,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        RoutesName.sendNotificationScreen,
                                        arguments: _allUserIds,
                                      );
                                    },
                                    index: 5,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: theme.colorScheme.onSurface.withAlpha(77),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 4.w,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}