import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/wellness_cache_service.dart';
import '../../../subscription/presentation/providers/premium_status_provider.dart';
import '../../providers/user_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../../core/services/data_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DataRepository _dataRepository = DataRepository.instance;
  String _appVersion = 'Unknown';
  String _cacheSize = 'Calculating...';
  SubscriptionModel? _subscription;
  StreamSubscription<DocumentSnapshot>? _subscriptionStream;
  String _downloadPath = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _calculateCacheSize();
    _loadSubscriptionData();
    _listenToSubscriptionChanges();
    _calculateDownloadPath();
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        final subscription = await _dataRepository.getSubscription(userId);
        if (mounted) {
          setState(() {
            _subscription = subscription;
          });
        }
      }
    } catch (e) {
      print('Error loading subscription: $e');
      if (mounted) {
        setState(() {
          _subscription = null;
        });
      }
    }
  }

  void _listenToSubscriptionChanges() {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId != null) {
      _subscriptionStream = FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(userId)
          .snapshots()
          .listen((doc) async {
        if (mounted) {
          final subscription = doc.exists
              ? SubscriptionModel.fromFirestore(doc.data()!, userId)
              : null;
          setState(() {
            _subscription = subscription;
          });
          Provider.of<PremiumStatusProvider>(context, listen: false)
              .updatePremiumStatus();
        }
      }, onError: (e) {
        print('Error listening to subscription changes: $e');
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading app version: $e', AppColors.error);
      }
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      int totalSize = 0;

      for (var dir in [tempDir, cacheDir]) {
        if (await dir.exists()) {
          await for (var entity in dir.list(recursive: true)) {
            if (entity is File) {
              totalSize += await entity.length();
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _cacheSize = '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = 'Error';
        });
        _showSnackBar('Error calculating cache size: $e', AppColors.error);
      }
    }
  }

  Future<void> _calculateDownloadPath() async {
    try {
      Directory saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Pictures/Wellness');
      } else {
        saveDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Pictures/Wellness');
      }
      if (mounted) {
        setState(() {
          _downloadPath = saveDir.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadPath = 'Error';
        });
        _showSnackBar('Error calculating download path: $e', AppColors.error);
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cache',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Cache size: $_cacheSize\nAre you sure you want to clear the app cache?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Clear',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final tempDir = await getTemporaryDirectory();
        final cacheDir = await getApplicationCacheDirectory();
        for (var dir in [tempDir, cacheDir]) {
          if (await dir.exists()) {
            await dir.delete(recursive: true);
            await dir.create(recursive: true);
          }
        }
        if (mounted) {
          setState(() {
            _cacheSize = '0.00 MB';
          });
          _showSnackBar('Cache cleared successfully!', AppColors.primary);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error clearing cache: $e', AppColors.error);
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        Provider.of<PremiumStatusProvider>(context, listen: false)
            .resetPremiumStatus();
        await WellnessCacheService().clearCache();
        await _authService.signOut();
        if (mounted) {
          _showSnackBar('Logged out successfully!', AppColors.primary);
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesName.loginScreen,
                  (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            'Error logging out: ${e.toString().replaceFirst('Exception: ', '')}',
            AppColors.error,
          );
        }
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: AppColors.lightBackground,
            fontSize: 14.sp,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.lightBackground,
          onPressed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _showSnackBar('Could not launch $url', AppColors.error);
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About Wellness App',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Wellness App\nVersion: $_appVersion\n© 2025 Wellness App. All rights reserved.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String svgIconPath,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? AppColors.shadow.withOpacity(0.5)
                : AppColors.lightTextPrimary.withOpacity(0.2),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: isSwitch ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  svgIconPath,
                  width: 26.sp,
                  height: 26.sp,
                  colorFilter: ColorFilter.mode(
                    isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 12.sp,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                isSwitch
                    ? Switch(
                  value: switchValue,
                  onChanged: onSwitchChanged,
                  activeColor: AppColors.primary,
                  inactiveThumbColor: AppColors.lightTextSecondary,
                  inactiveTrackColor:
                  AppColors.lightTextSecondary.withOpacity(0.3),
                )
                    : SvgPicture.asset(
                  'assets/icons/svg/ic_arrow_forward.svg',
                  width: 18.sp,
                  height: 18.sp,
                  colorFilter: ColorFilter.mode(
                    isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Container(
            height: 2.h,
            width: 50.w,
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Colors.grey[850]!, AppColors.darkBackground]
                  : [AppColors.lightSurface, AppColors.lightBackground],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
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
                        padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        child: Container(
                          height: 56.h,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF121212)
                                : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: isDarkMode
                                ? []
                                : [
                              BoxShadow(
                                color:
                                AppColors.lightTextPrimary.withOpacity(0.2),
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
                                  color: isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                onPressed: () => Navigator.pop(context),
                                tooltip: 'Back',
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Profile',
                                    style:
                                    theme.textTheme.titleLarge?.copyWith(
                                      color: isDarkMode
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
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
                                    color: isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  onPressed: () => Navigator.pop(context),
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
                      padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer2<UserProvider, PremiumStatusProvider>(
                            builder:
                                (context, userProvider, premiumProvider, child) {
                              final user = userProvider.user;
                              final userName = user?.displayName ?? 'User';
                              final userEmail = user?.email ?? 'No email';
                              final userPhotoUrl = user?.photoURL;
                              final joinedDate =
                              _formatDate(user?.metadata.creationTime);
                              final isPremium = premiumProvider.canAccessPremium &&
                                  _subscription != null &&
                                  _subscription!.status == 'active' &&
                                  (_subscription!.endDate == null ||
                                      _subscription!.endDate!
                                          .isAfter(DateTime.now()));
                              final planName = _subscription?.planId != null &&
                                  _subscription!.status == 'active' &&
                                  (_subscription!.endDate == null ||
                                      _subscription!.endDate!
                                          .isAfter(DateTime.now()))
                                  ? _subscription!.planId!.toUpperCase()
                                  : 'N/A';
                              final memberSince = user?.metadata.creationTime != null
                                  ? user!.metadata.creationTime!.year.toString()
                                  : 'N/A';

                              if (isPremium) {
                                // COMPACT PREMIUM CARD WITH DIAMOND PATTERN
                                return Column(
                                  children: [
                                    // Premium black and gold card
                                    Container(
                                      width: double.infinity,
                                      height: 180.h,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF000000), // Deep black
                                            Color(0xFF141414), // Rich black
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10.r,
                                            spreadRadius: 1.r,
                                            offset: Offset(0, 4.h),
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFFD4AF37).withOpacity(0.2),
                                            blurRadius: 8.r,
                                            spreadRadius: 0,
                                            offset: Offset(0, 1.h),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                                          width: 1.w,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Diamond pattern background
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: DiamondPatternPainter(),
                                            ),
                                          ),

                                          // Card content
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 12.h,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Top row with plan badge and logo
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Premium badge
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 10.w,
                                                        vertical: 5.h,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            Color(0xFFD4AF37), // Gold
                                                            Color(0xFFB8860B), // Dark gold
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(20.r),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.2),
                                                            blurRadius: 4.r,
                                                            offset: Offset(0, 2.h),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            FontAwesomeIcons.diamond,
                                                            size: 10.sp,
                                                            color: Colors.black,
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          Text(
                                                            planName,
                                                            style: TextStyle(
                                                              fontSize: 10.sp,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Logo
                                                    ShaderMask(
                                                      shaderCallback: (bounds) => const LinearGradient(
                                                        colors: [
                                                          Color(0xFFD4AF37),
                                                          Color(0xFFF0E68C),
                                                          Color(0xFFD4AF37),
                                                        ],
                                                      ).createShader(bounds),
                                                      child: Text(
                                                        'WELLNESS',
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 1.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // Center content with crown and name
                                                Expanded(
                                                  child: Center(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        // Crown icon
                                                        Container(
                                                          width: 40.w,
                                                          height: 40.w,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: const Color(0xFFD4AF37),
                                                              width: 1.w,
                                                            ),
                                                          ),
                                                          child: Center(
                                                            child: ShaderMask(
                                                              shaderCallback: (bounds) => const LinearGradient(
                                                                colors: [
                                                                  Color(0xFFD4AF37),
                                                                  Color(0xFFF0E68C),
                                                                ],
                                                              ).createShader(bounds),
                                                              child: FaIcon(
                                                                FontAwesomeIcons.crown,
                                                                size: 18.sp,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 12.w),

                                                        // Premium member name
                                                        Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'PREMIUM MEMBER',
                                                              style: TextStyle(
                                                                fontSize: 10.sp,
                                                                fontWeight: FontWeight.w500,
                                                                color: const Color(0xFFD4AF37),
                                                                letterSpacing: 1.0,
                                                              ),
                                                            ),
                                                            SizedBox(height: 4.h),
                                                            Text(
                                                              userName.toUpperCase(),
                                                              style: TextStyle(
                                                                fontSize: 18.sp,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                                letterSpacing: 0.5,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                // Stats row at bottom
                                                Container(
                                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(
                                                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                                                        width: 1.h,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                    children: [
                                                      _buildStat('MEMBER SINCE', memberSince),
                                                      _buildVerticalDivider(),
                                                      _buildStat('STATUS', 'ACTIVE'),
                                                      _buildVerticalDivider(),
                                                      _buildStat('BENEFITS', '100%'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Decorative corners
                                          Positioned(
                                            top: 8.h,
                                            left: 8.w,
                                            child: _buildCorner(),
                                          ),
                                          Positioned(
                                            top: 8.h,
                                            right: 8.w,
                                            child: Transform.rotate(
                                              angle: pi / 2,
                                              child: _buildCorner(),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8.h,
                                            right: 8.w,
                                            child: Transform.rotate(
                                              angle: pi,
                                              child: _buildCorner(),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8.h,
                                            left: 8.w,
                                            child: Transform.rotate(
                                              angle: 3 * pi / 2,
                                              child: _buildCorner(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 16.h),

                                    // User info card
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(16.w),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.grey[900]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37).withOpacity(0.3),
                                          width: 1.w,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8.r,
                                            offset: Offset(0, 2.h),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // User avatar
                                          Container(
                                            width: 60.w,
                                            height: 60.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFD4AF37),
                                                width: 2.w,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                                                  blurRadius: 6.r,
                                                  offset: Offset(0, 2.h),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: userPhotoUrl != null
                                                  ? CachedNetworkImage(
                                                imageUrl: userPhotoUrl,
                                                width: 60.w,
                                                height: 60.w,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Center(
                                                  child: CircularProgressIndicator(
                                                    color: const Color(0xFFD4AF37),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => SvgPicture.asset(
                                                  'assets/icons/svg/ic_user.svg',
                                                  width: 30.sp,
                                                  height: 30.sp,
                                                  colorFilter: ColorFilter.mode(
                                                    isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              )
                                                  : SvgPicture.asset(
                                                'assets/icons/svg/ic_user.svg',
                                                width: 30.sp,
                                                height: 30.sp,
                                                colorFilter: ColorFilter.mode(
                                                  isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(width: 16.w),

                                          // User details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  userEmail,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  'Joined: $joinedDate',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(20.w),
                                  margin: EdgeInsets.only(bottom: 20.h),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? AppColors.darkSurface
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? AppColors.darkTextHint
                                          : AppColors.lightTextHint,
                                      width: 1.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode
                                            ? AppColors.shadow.withOpacity(0.5)
                                            : AppColors.lightTextPrimary
                                            .withOpacity(0.2),
                                        blurRadius: 8.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 48.r,
                                        backgroundColor: isDarkMode
                                            ? AppColors.darkSurface
                                            : AppColors.lightBackground,
                                        child: userPhotoUrl != null
                                            ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: userPhotoUrl,
                                            width: 96.r,
                                            height: 96.r,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Center(
                                                  child: CircularProgressIndicator(
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                SvgPicture.asset(
                                                  'assets/icons/svg/ic_user.svg',
                                                  width: 60.sp,
                                                  height: 60.sp,
                                                  colorFilter: ColorFilter.mode(
                                                    isDarkMode
                                                        ? AppColors
                                                        .darkTextPrimary
                                                        : AppColors
                                                        .lightTextPrimary,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                          ),
                                        )
                                            : SvgPicture.asset(
                                          'assets/icons/svg/ic_user.svg',
                                          width: 60.sp,
                                          height: 60.sp,
                                          colorFilter: ColorFilter.mode(
                                            isDarkMode
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        userName,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                          color: isDarkMode
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        userEmail,
                                        style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 14.sp,
                                          fontFamily: 'Poppins',
                                          color: isDarkMode
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Joined: $joinedDate',
                                        style:
                                        theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 12.sp,
                                          fontFamily: 'Poppins',
                                          color: isDarkMode
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20.h),
                                      ElevatedButton.icon(
                                        onPressed: () => Navigator.pushNamed(
                                            context, RoutesName.subscriptionScreen),
                                        icon: Icon(Icons.rocket_launch, size: 18.sp),
                                        label: Text(
                                          'Upgrade to Premium',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 24.w, vertical: 12.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(20.r),
                                          ),
                                          elevation: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          _buildSectionHeader('Account'),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_edit_profile.svg',
                            title: 'Edit Profile',
                            description:
                            'Update your name, email, or profile picture',
                            onTap: () => Navigator.pushNamed(
                                context, RoutesName.editProfileScreen),
                          ),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_lock.svg',
                            title: 'Change Password',
                            description: 'Secure your account with a new password',
                            onTap: () => Navigator.pushNamed(
                                context, RoutesName.changePasswordScreen),
                          ),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_heart.svg',
                            title: 'Content Preferences',
                            description: 'Personalize your wellness content',
                            onTap: () => Navigator.pushNamed(
                                context, RoutesName.userPrefsScreen,
                                arguments: true),
                          ),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_exit.svg',
                            title: 'Logout',
                            description: 'Sign out of your account',
                            onTap: _handleLogout,
                          ),
                          _buildSectionHeader('Appearance'),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_theme.svg',
                            title: 'Dark Mode',
                            description: 'Switch between light and dark themes',
                            onTap: () {},
                            isSwitch: true,
                            switchValue: themeProvider.isDarkMode,
                            onSwitchChanged: (value) {
                              themeProvider.toggleTheme(value);
                            },
                          ),
                          _buildSectionHeader('Subscription'),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_premium.svg',
                            title: 'Manage Subscription',
                            description: 'View and upgrade your plan',
                            onTap: () => Navigator.pushNamed(
                                context, RoutesName.subscriptionScreen),
                          ),
                          _buildSectionHeader('Downloads'),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_download.svg',
                            title: 'Download Location',
                            description: 'Default path: $_downloadPath',
                            onTap: () {},
                          ),
                          _buildSectionHeader('Storage'),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_delete.svg',
                            title: 'Clear App Cache',
                            description:
                            'Free up space by clearing cache ($_cacheSize)',
                            onTap: _clearCache,
                          ),
                          _buildSectionHeader('Legal'),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_privacy.svg',
                            title: 'Privacy Policy',
                            description: 'Review our privacy practices',
                            onTap: () =>
                                _launchUrl('https://example.com/privacy'),
                          ),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_terms.svg',
                            title: 'Terms and Conditions',
                            description: 'Understand our terms of service',
                            onTap: () => _launchUrl('https://example.com/terms'),
                          ),
                          _buildSectionHeader('About'),
                          _buildMenuItem(
                            svgIconPath: 'assets/icons/svg/ic_about.svg',
                            title: 'About App',
                            description: 'Learn more about Wellness App',
                            onTap: _showAboutDialog,
                          ),
                          SizedBox(height: 80.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFFD4AF37), // Gold
                Color(0xFFF0E68C), // Light gold
              ],
            ).createShader(bounds);
          },
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Will be overridden by shader
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 8.sp,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24.h,
      width: 1.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.1),
            const Color(0xFFD4AF37).withOpacity(0.5),
            const Color(0xFFD4AF37).withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner() {
    return Container(
      width: 20.w,
      height: 20.h,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.w),
          left: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.w),
        ),
      ),
    );
  }
}

class DiamondPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pattern = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Create diamond grid pattern
    final diamondSize = size.width / 15;
    final rows = (size.height / diamondSize).ceil() + 1;
    final cols = (size.width / diamondSize).ceil() + 1;

    for (int i = -1; i < rows; i++) {
      for (int j = -1; j < cols; j++) {
        final path = Path();
        final centerX = j * diamondSize + (i % 2 == 0 ? 0 : diamondSize / 2);
        final centerY = i * diamondSize;

        path.moveTo(centerX, centerY - diamondSize / 2);
        path.lineTo(centerX + diamondSize / 2, centerY);
        path.lineTo(centerX, centerY + diamondSize / 2);
        path.lineTo(centerX - diamondSize / 2, centerY);
        path.close();

        canvas.drawPath(path, pattern);
      }
    }

    // Add some sparkle effects
    final sparkle = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Fixed seed for consistent pattern
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.8 + random.nextDouble() * 1.2;

      canvas.drawCircle(Offset(x, y), radius, sparkle);
    }

    // Add subtle gold gradient glow
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD4AF37).withOpacity(0.08),
          Colors.transparent,
        ],
        radius: 1.0,
        center: Alignment.center,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}