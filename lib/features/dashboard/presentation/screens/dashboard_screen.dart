import 'dart:async';
import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/dashboard/data/models/dashboard_data.dart';
import 'package:wellness_app/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:wellness_app/features/dashboard/domain/usecases/dashboard_usecase.dart';
import 'package:wellness_app/features/dashboard/domain/utils/user_utils.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'dart:developer';
import '../../../../common/widgets/horizontal_list_widget.dart';
import '../../../../common/widgets/section_header_widget.dart';
import '../../../profile/providers/user_provider.dart';
import '../../../subscription/presentation/providers/premium_status_provider.dart';
import '../widgets/discover_by_category_widget.dart';
import '../widgets/featured_quotes_widget.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/quote_card.dart';
import '../widgets/tips_card.dart';

class UserDashboardScreen extends StatefulWidget {
  final VoidCallback onViewAllCategories;

  const UserDashboardScreen({
    super.key,
    required this.onViewAllCategories,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DashboardUseCase _dashboardUseCase = DashboardUseCase();
  final UserUtils _userUtils = UserUtils();
  final DashboardRepository _dashboardRepository = DashboardRepository();
  final DataRepository _dataRepository = DataRepository.instance;
  AnimationController? _lottieController;
  bool _showShimmer = true;
  bool _isInitializing = true;
  DashboardData? _cachedData;
  Future<DashboardData>? _dashboardFuture;
  StreamSubscription<DocumentSnapshot>? _subscriptionStream;

  @override
  void initState() {
    super.initState();
    final userId = _authService.getCurrentUser()?.uid ?? '';
    log('Current user: $userId', name: 'UserDashboardScreen');
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    if (userId.isNotEmpty) {
      _dashboardFuture = Future.value(_emptyDashboardData());
      _initializeWithCache(userId);
      _listenToSubscriptionChanges(userId);
    } else {
      _showShimmer = false;
      _isInitializing = false;
      _cachedData = _emptyDashboardData();
      log('No user ID found, skipping data fetch', name: 'UserDashboardScreen');
    }
  }

  void _listenToSubscriptionChanges(String userId) {
    if (userId.isNotEmpty) {
      _subscriptionStream = FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(userId)
          .snapshots()
          .listen((doc) async {
        if (mounted) {
          final subscription = doc.exists
              ? SubscriptionModel.fromFirestore(doc.data()!, userId)
              : null;
          final canAccessPremium = subscription != null &&
              subscription.status == 'active' &&
              (subscription.endDate == null ||
                  subscription.endDate!.isAfter(DateTime.now()));
          Provider.of<PremiumStatusProvider>(context, listen: false)
              .setPremiumStatus(canAccessPremium);
          log('Subscription updated for user $userId: canAccessPremium=$canAccessPremium',
              name: 'UserDashboardScreen');
        }
      }, onError: (e) {
        log('Error listening to subscription changes: $e', name: 'UserDashboardScreen');
        if (mounted) {
          Provider.of<PremiumStatusProvider>(context, listen: false)
              .setPremiumStatus(false);
        }
      });
    }
  }

  Future<void> _initializeWithCache(String userId) async {
    try {
      final cachedData = await _dashboardRepository.getCachedDashboardData(userId);

      if (cachedData != null) {
        setState(() {
          _cachedData = cachedData;
          _showShimmer = false;
          _isInitializing = false;
        });
        // Update premium status from cache
        final subscription = cachedData.subscription;
        final canAccessPremium = subscription != null &&
            subscription.status == 'active' &&
            (subscription.endDate == null ||
                subscription.endDate!.isAfter(DateTime.now()));
        Provider.of<PremiumStatusProvider>(context, listen: false)
            .setPremiumStatus(canAccessPremium);
        log('Initialized from cache for user $userId: canAccessPremium=$canAccessPremium',
            name: 'UserDashboardScreen');
      } else {
        setState(() {
          _showShimmer = true;
        });
      }

      _dashboardFuture = _initializeDashboardData(userId);
    } catch (e) {
      log('Error checking cache: $e', name: 'UserDashboardScreen');
      setState(() {
        _showShimmer = true;
        _dashboardFuture = _initializeDashboardData(userId);
      });
    }
  }

  Future<DashboardData> _initializeDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('No user ID found in _initializeDashboardData', name: 'UserDashboardScreen');
      setState(() {
        _showShimmer = false;
        _isInitializing = false;
        _cachedData = _emptyDashboardData();
      });
      Provider.of<PremiumStatusProvider>(context, listen: false).setPremiumStatus(false);
      return _cachedData!;
    }

    try {
      final dashboardData = await _dashboardRepository.getDashboardData(userId);
      setState(() {
        _cachedData = dashboardData;
        _showShimmer = false;
        _isInitializing = false;
      });
      // Update premium status
      final subscription = dashboardData.subscription;
      final canAccessPremium = subscription != null &&
          subscription.status == 'active' &&
          (subscription.endDate == null ||
              subscription.endDate!.isAfter(DateTime.now()));
      Provider.of<PremiumStatusProvider>(context, listen: false)
          .setPremiumStatus(canAccessPremium);
      log(
        'Dashboard data loaded for user $userId: '
            'user=${dashboardData.user?.userName ?? "null"}, '
            'tips=${dashboardData.tips.length}, '
            'categories=${dashboardData.categories.length}, '
            'notifications=${dashboardData.notifications.length}, '
            'canAccessPremium=$canAccessPremium',
        name: 'UserDashboardScreen',
      );
      return dashboardData;
    } catch (e, stackTrace) {
      log(
        'Error initializing dashboard data for user $userId: $e',
        name: 'UserDashboardScreen',
        stackTrace: stackTrace,
      );
      setState(() {
        _showShimmer = false;
        _isInitializing = false;
        _cachedData ??= _emptyDashboardData();
      });
      Provider.of<PremiumStatusProvider>(context, listen: false).setPremiumStatus(false);
      return _cachedData!;
    }
  }

  void _retryFetchData(String userId) {
    setState(() {
      _showShimmer = true;
      _cachedData = null;
      _dashboardFuture = _initializeDashboardData(userId);
    });
    log('Retrying data fetch for user $userId', name: 'UserDashboardScreen');
  }

  Future<void> _refreshData(String userId) async {
    try {
      await _dashboardRepository.clearDashboardCache(userId);
      setState(() {
        _showShimmer = true;
        _cachedData = null;
        _dashboardFuture = _initializeDashboardData(userId);
      });
      log('Refreshed data and cleared cache for user $userId', name: 'UserDashboardScreen');
      // Force refresh premium status
      await Provider.of<PremiumStatusProvider>(context, listen: false).updatePremiumStatus();
    } catch (e, stackTrace) {
      log('Error refreshing data for user $userId: $e', name: 'UserDashboardScreen', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData)),
      );
    }
  }

  DashboardData _emptyDashboardData() {
    return DashboardData(
      user: null,
      preferences: [],
      userPreference: null,
      categories: [],
      tips: [],
      notifications: [],
      reminders: [],
      favorites: [],
      subscription: null,
      transactions: [],
    );
  }

  @override
  void dispose() {
    _lottieController?.dispose();
    _subscriptionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final userId = _authService.getCurrentUser()?.uid ?? '';

    if (userId.isEmpty) {
      log('No user ID found, redirecting to login', name: 'UserDashboardScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      });
      return const SizedBox.shrink();
    }

    return Consumer<PremiumStatusProvider>(
      builder: (context, premiumProvider, child) {
        if (premiumProvider.isLoading && _isInitializing) {
          return const DashboardShimmer();
        }

        if (_cachedData != null) {
          return _buildDashboardContent(context, _cachedData!, userId, theme, isDarkMode);
        }

        if (_isInitializing) {
          return _showShimmer ? const DashboardShimmer() : const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<DashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            log(
              'FutureBuilder state: connectionState=${snapshot.connectionState}, '
                  'hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, '
                  'error=${snapshot.error}, showShimmer=$_showShimmer',
              name: 'UserDashboardScreen',
            );

            if (snapshot.connectionState == ConnectionState.waiting && _showShimmer) {
              return const DashboardShimmer();
            }

            if (snapshot.hasError && !snapshot.hasData) {
              log('FutureBuilder error: ${snapshot.error}', name: 'UserDashboardScreen');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.errorLoadingData,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Poppins',
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => _retryFetchData(userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? AppColors.primary : Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        minimumSize: Size(120.w, 48.h),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.retry,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasData) {
              final data = snapshot.data!;
              if (data.user != null || _cachedData != null) {
                return _buildDashboardContent(context, data, userId, theme, isDarkMode);
              }
            }

            return const DashboardShimmer();
          },
        );
      },
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, DashboardData data, String userId, ThemeData theme, bool isDarkMode) {
    final userPreferenceIds = data.userPreference?.preferences
        .map((entry) => entry.preferenceId)
        .toSet() ??
        <String>{};
    final filteredCategories = _dashboardUseCase.filterCategories(
      data.categories,
      userPreferenceIds,
    );
    final featuredQuotes = _dashboardUseCase.filterFeaturedQuotes(
      data.tips,
      userPreferenceIds,
    );
    final categoryTips = _dashboardUseCase.groupTipsByCategory(
      data.tips,
      filteredCategories,
      userPreferenceIds,
    );
    final validCategories = filteredCategories
        .where((category) => categoryTips.containsKey(category.categoryId))
        .toList();

    log(
      'Processed data: user=${data.user?.userName ?? "null"}, '
          'categories=${validCategories.length}, '
          'featuredQuotes=${featuredQuotes.length}, '
          'categoryTips=${categoryTips.keys.length}, '
          'notifications=${data.notifications.length}',
      name: 'UserDashboardScreen',
    );

    if (data.user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.noDataAvailable,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'Poppins',
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _retryFetchData(userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppColors.primary : Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                minimumSize: Size(120.w, 48.h),
              ),
              child: Text(
                AppLocalizations.of(context)!.retry,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshData(userId),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? null : Colors.white,
          gradient: isDarkMode
              ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
          )
              : null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Consumer2<UserProvider, PremiumStatusProvider>(
                        builder: (context, userProvider, premiumProvider, child) {
                          final user = userProvider.user;
                          final userName = user?.displayName ?? 'User';
                          final userPhotoUrl = user?.photoURL;
                          final isPremium = premiumProvider.canAccessPremium;

                          return Row(
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30.r),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RoutesName.profileScreen,
                                    );
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      if (isPremium)
                                        Container(
                                          width: 64.w,
                                          height: 64.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.yellow.shade700,
                                                Colors.amber.shade500,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDarkMode
                                                    ? Colors.black.withOpacity(0.3)
                                                    : Colors.black.withOpacity(0.15),
                                                blurRadius: 12.r,
                                                spreadRadius: 3.r,
                                                offset: Offset(0, 2.h),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isPremium
                                                ? Colors.transparent
                                                : (isDarkMode
                                                ? Colors.grey.shade600
                                                : Colors.grey.shade300),
                                            width: isPremium ? 0 : 2.w,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDarkMode
                                                  ? Colors.black.withOpacity(0.3)
                                                  : Colors.black.withOpacity(0.15),
                                              blurRadius: 10.r,
                                              spreadRadius: 2.r,
                                              offset: Offset(0, 2.h),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 28.r,
                                          backgroundColor: isPremium
                                              ? Colors.transparent
                                              : (isDarkMode
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade200),
                                          backgroundImage: userPhotoUrl != null
                                              ? CachedNetworkImageProvider(userPhotoUrl)
                                              : null,
                                          child: userPhotoUrl == null
                                              ? SvgPicture.asset(
                                            'assets/icons/svg/ic_user.svg',
                                            width: 28.sp,
                                            height: 28.sp,
                                            colorFilter: ColorFilter.mode(
                                              isDarkMode ? Colors.white : Colors.black,
                                              BlendMode.srcIn,
                                            ),
                                            semanticsLabel: 'User profile',
                                          )
                                              : null,
                                        ),
                                      ),
                                      if (isPremium)
                                        Positioned(
                                          top: -16.h,
                                          child: FaIcon(
                                            FontAwesomeIcons.crown,
                                            size: 24.sp,
                                            color: Colors.yellow.shade700,
                                            semanticLabel: 'Premium User',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 200.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.hello(
                                        _userUtils.getFirstName(
                                          userName,
                                          AppLocalizations.of(context)!.defaultUserName,
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontFamily: 'Poppins',
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 22.sp,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _userUtils.getTimeBasedGreeting(
                                        goodMorning: AppLocalizations.of(context)!.goodMorning,
                                        goodAfternoon: AppLocalizations.of(context)!.goodAfternoon,
                                        goodEvening: AppLocalizations.of(context)!.goodEvening,
                                        goodNight: AppLocalizations.of(context)!.goodNight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'Poppins',
                                        color: isDarkMode
                                            ? AppColors.darkTextSecondary
                                            : Colors.grey.shade600,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: SvgPicture.asset(
                                'assets/icons/svg/ic_bell.svg',
                                width: 24.sp,
                                height: 24.sp,
                                colorFilter: ColorFilter.mode(
                                  isDarkMode ? AppColors.primary : Colors.black,
                                  BlendMode.srcIn,
                                ),
                                semanticsLabel: 'Notifications',
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  RoutesName.notificationScreen,
                                );
                              },
                            ),
                          ),
                          if (data.notifications.where((n) => !n.isRead).isNotEmpty)
                            Positioned(
                              right: -4.w,
                              top: -4.h,
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDarkMode ? null : Colors.black,
                                  gradient: isDarkMode
                                      ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.7),
                                    ],
                                  )
                                      : null,
                                ),
                                child: Text(
                                  data.notifications.where((n) => !n.isRead).length > 9
                                      ? '9+'
                                      : '${data.notifications.where((n) => !n.isRead).length}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (featuredQuotes.isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    SectionHeaderWidget(
                      title: AppLocalizations.of(context)!.featuredQuotes,
                      onViewAll: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.tipsDetailScreen,
                          arguments: {
                            'tip': featuredQuotes.isNotEmpty ? featuredQuotes.first : null,
                            'categoryName': AppLocalizations.of(context)!.featuredQuotes,
                            'userId': userId,
                            'featuredTips': featuredQuotes,
                          },
                        );
                      },
                      viewAllText: AppLocalizations.of(context)!.viewAll,
                      theme: theme,
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 12.h),
                    FeaturedQuotesWidget(
                      key: ValueKey(featuredQuotes.length),
                      featuredTips: featuredQuotes,
                      theme: theme,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                  DiscoverByCategoryWidget(
                    validCategories: validCategories,
                    categoryTips: categoryTips,
                    theme: theme,
                    isDarkMode: isDarkMode,
                    onViewAllCategories: widget.onViewAllCategories,
                  ),
                  SizedBox(height: 20.h),
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? null : Colors.white,
                          gradient: isDarkMode
                              ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.darkSurface,
                              AppColors.darkSurface.withOpacity(0.7),
                            ],
                          )
                              : null,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? AppColors.darkSurface.withOpacity(0.1)
                                  : Colors.black.withAlpha(26),
                              blurRadius: 6.r,
                              offset: Offset(0, 2.h),
                            ),
                            if (!isDarkMode)
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 6.r,
                                offset: Offset(0, -2.h),
                              ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.reminderScreen,
                              arguments: null,
                            );
                          },
                          borderRadius: BorderRadius.circular(20.r),
                          child: Container(
                            height: 120.h,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20.w,
                                  top: -20.h,
                                  child: Opacity(
                                    opacity: 0.1,
                                    child: Icon(
                                      Icons.access_time,
                                      size: 80.sp,
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.black.withAlpha(178),
                                      semanticLabel: 'Clock icon',
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 70.w,
                                      height: 70.w,
                                      child: _lottieController != null
                                          ? Lottie.asset(
                                        'assets/animations/clock.json',
                                        fit: BoxFit.cover,
                                        controller: _lottieController,
                                      )
                                          : const SizedBox.shrink(),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!.setReminder,
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18.sp,
                                              color: isDarkMode ? Colors.white : Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 6.h),
                                          Text(
                                            AppLocalizations.of(context)!.neverMissYourFavoriteQuotes,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontFamily: 'Poppins',
                                              fontSize: 15.sp,
                                              color: isDarkMode
                                                  ? AppColors.darkTextSecondary
                                                  : Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (var category in validCategories) ...[
                    if (categoryTips[category.categoryId]?.isNotEmpty ?? false) ...[
                      SizedBox(height: 20.h),
                      SectionHeaderWidget(
                        title: category.categoryName,
                        onViewAll: () {
                          Navigator.pushNamed(
                            context,
                            RoutesName.categoryDetailScreen,
                            arguments: category,
                          );
                        },
                        viewAllText: AppLocalizations.of(context)!.viewAll,
                        theme: theme,
                        isDarkMode: isDarkMode,
                      ),
                      SizedBox(height: 12.h),
                      HorizontalListWidget<TipModel>(
                        items: categoryTips[category.categoryId] ?? [],
                        itemBuilder: (tip) => tip.tipsType == 'quote'
                            ? QuoteCard(
                          tip: tip,
                          theme: theme,
                          isDarkMode: isDarkMode,
                          categoryName: category.categoryName,
                          featuredTips: categoryTips[category.categoryId] ?? [],
                        )
                            : TipCard(
                          tip: tip,
                          theme: theme,
                          isDarkMode: isDarkMode,
                          categoryName: category.categoryName,
                          featuredTips: categoryTips[category.categoryId] ?? [],
                        ),
                        emptyMessage: AppLocalizations.of(context)!.noDataAvailable,
                        theme: theme,
                        isDarkMode: isDarkMode,
                        height: 150,
                        placeholderCount: 3,
                      ),
                    ],
                  ],
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}