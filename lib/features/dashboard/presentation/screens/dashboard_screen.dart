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
import 'package:wellness_app/features/preferences/data/models/user_preference_model.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'dart:developer';
import '../../../../common/widgets/horizontal_list_widget.dart';
import '../../../../common/widgets/section_header_widget.dart';
import '../../../imageViewer/presentation/widgets/image_card.dart';
import '../../../preferences/presentation/provider/user_preference_provider.dart';
import '../../../profile/providers/user_provider.dart';
import '../../../subscription/presentation/providers/premium_status_provider.dart';
import '../../../videoPlayer/presentation/widgets/short_video_card.dart';
import '../providers/notification_count_provider.dart';
import '../widgets/discover_by_category_widget.dart';
import '../widgets/featured_quotes_widget.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/quote_card.dart';
import '../widgets/tips_card.dart';
import '../../../audioPlayer/presentation/widgets/audio_card.dart';
import '../../../videoPlayer/presentation/widgets/video_player_card.dart';

class UserDashboardScreen extends StatefulWidget {
  final VoidCallback onViewAllCategories;

  const UserDashboardScreen({
    super.key,
    required this.onViewAllCategories,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DashboardUseCase _dashboardUseCase = DashboardUseCase();
  final UserUtils _userUtils = UserUtils();
  final DashboardRepository _dashboardRepository = DashboardRepository.instance;
  final DataRepository _dataRepository = DataRepository.instance;

  AnimationController? _lottieController;
  bool _showShimmer = false; // Default to false, only show in online mode if needed
  bool _isInitializing = false; // Track if we're still initializing
  bool _isRefreshing = false; // Prevent multiple simultaneous refreshes
  bool _isOffline = false; // Track offline status
  bool _isConnectivityChecked = false; // Track if connectivity check is complete
  DashboardData? _cachedData; // Data to display
  Future<DashboardData>? _dashboardFuture; // Future for loading data
  StreamSubscription<DocumentSnapshot>? _subscriptionStream;
  Map<String, List<TipModel>>? _processedCategoryTips; // Cache processed data

  @override
  void initState() {
    super.initState();
    final userId = _authService.getCurrentUser()?.uid ?? '';
    log('Current user: $userId', name: 'UserDashboardScreen');

    // Check connectivity first to determine offline status
    _checkConnectivity().then((_) {
      // Initialize Lottie controller only if we need it
      _lottieController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 5),
      );

      if (userId.isNotEmpty) {
        _initializeForUser(userId);
      } else {
        _cachedData = _emptyDashboardData();
        _isConnectivityChecked = true; // Ensure UI can render
        log('No user ID found, skipping data fetch', name: 'UserDashboardScreen');
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      _isOffline = await _dashboardRepository.isOffline();
      log('Device is ${_isOffline ? 'offline' : 'online'}', name: 'UserDashboardScreen');
    } catch (e) {
      _isOffline = false; // Default to online if check fails
      log('Error checking connectivity: $e', name: 'UserDashboardScreen');
    }
    if (mounted) {
      setState(() {
        _isConnectivityChecked = true;
        _showShimmer = false; // Ensure no shimmer in offline mode
      });
    }
  }

  void _initializeForUser(String userId) {
    // Try synchronous cache first for instant display
    final instantData = _dashboardRepository.getLastDashboardDataSync(userId);
    if (instantData != null && instantData.user != null) {
      _cachedData = instantData;
      _lottieController?.repeat(); // Start animation
      _updatePremiumStatus(instantData.subscription);
      log('Loaded instant data from cache for user $userId', name: 'UserDashboardScreen');
      // Load fresh data in background
      _loadDataInBackground(userId);
    } else {
      // No instant data, check other caches
      setState(() {
        _isInitializing = true;
        _showShimmer = !_isOffline; // No shimmer in offline mode
      });
      _initializeWithCache(userId);
    }

    _listenToSubscriptionChanges(userId);

    // Load providers post-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserPreferenceProvider>(context, listen: false).loadUserPreferences(userId);
      Provider.of<NotificationCountProvider>(context, listen: false).fetchUnreadNotificationCount();
    });
  }

  void _loadDataInBackground(String userId) {
    _dashboardFuture = _dashboardRepository.getDashboardData(userId).then((data) {
      if (mounted && data.user != null) {
        setState(() {
          _cachedData = data;
          _processedCategoryTips = null; // Clear processed data cache
        });
        _updatePremiumStatus(data.subscription);
      }
      return data;
    }).catchError((e) {
      log('Background data load error: $e', name: 'UserDashboardScreen');
      return _cachedData ?? _emptyDashboardData();
    });
  }

  Future<void> _initializeWithCache(String userId) async {
    try {
      final cachedData = await _dashboardRepository.getCachedDashboardData(userId);
      if (cachedData != null && cachedData.user != null) {
        if (mounted) {
          setState(() {
            _cachedData = cachedData;
            _showShimmer = false; // No shimmer, even in online mode
            _isInitializing = false;
          });
          _lottieController?.repeat();
          _updatePremiumStatus(cachedData.subscription);
          log('Initialized from SQLite cache for user $userId', name: 'UserDashboardScreen');
        }
        if (!_isOffline) {
          _loadDataInBackground(userId); // Refresh in background if online
        }
      } else {
        // No cache, load data
        _dashboardFuture = _initializeDashboardData(userId);
      }
    } catch (e) {
      log('Error checking cache: $e', name: 'UserDashboardScreen');
      _dashboardFuture = _initializeDashboardData(userId);
    }
  }

  Future<DashboardData> _initializeDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('No user ID found in _initializeDashboardData', name: 'UserDashboardScreen');
      if (mounted) {
        setState(() {
          _showShimmer = false; // No shimmer
          _isInitializing = false;
          _cachedData = _emptyDashboardData();
        });
      }
      return _emptyDashboardData();
    }

    try {
      final dashboardData = await _dashboardRepository.getDashboardData(userId);
      if (mounted) {
        setState(() {
          _cachedData = dashboardData;
          _showShimmer = false; // No shimmer
          _isInitializing = false;
          _processedCategoryTips = null;
        });
        _lottieController?.repeat();
        _updatePremiumStatus(dashboardData.subscription);
        log('Dashboard data loaded for user $userId: user=${dashboardData.user?.userName ?? "null"}', name: 'UserDashboardScreen');
      }
      return dashboardData;
    } catch (e, stackTrace) {
      log('Error initializing dashboard data for user $userId: $e', name: 'UserDashboardScreen', stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _showShimmer = false; // No shimmer
          _isInitializing = false;
          _cachedData ??= _emptyDashboardData();
        });
      }
      return _cachedData ?? _emptyDashboardData();
    }
  }

  void _updatePremiumStatus(SubscriptionModel? subscription) {
    if (!mounted) return;
    final canAccessPremium = subscription != null &&
        subscription.status == 'active' &&
        (subscription.endDate == null || subscription.endDate!.isAfter(DateTime.now()));
    Provider.of<PremiumStatusProvider>(context, listen: false).setPremiumStatus(canAccessPremium);
    log('Premium status updated: $canAccessPremium', name: 'UserDashboardScreen');
  }

  void _listenToSubscriptionChanges(String userId) {
    if (userId.isEmpty || _isOffline) return;
    _subscriptionStream = FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(userId)
        .snapshots()
        .listen((doc) async {
      if (mounted) {
        final subscription = doc.exists ? SubscriptionModel.fromFirestore(doc.data()!, userId) : null;
        _updatePremiumStatus(subscription);
      }
    }, onError: (e) {
      log('Error listening to subscription changes: $e', name: 'UserDashboardScreen');
      if (mounted) {
        Provider.of<PremiumStatusProvider>(context, listen: false).setPremiumStatus(false);
      }
    });
  }

  void _retryFetchData(String userId) {
    if (mounted) {
      setState(() {
        _showShimmer = !_isOffline; // Only show shimmer if online
        _isInitializing = true;
        _cachedData = null;
        _processedCategoryTips = null;
        _dashboardFuture = _initializeDashboardData(userId);
      });
    }
    log('Retrying data fetch for user $userId', name: 'UserDashboardScreen');
  }

  Future<void> _refreshData(String userId) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    await _checkConnectivity();
    if (_isOffline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No internet connection"),
          ),

        );
      }
      _isRefreshing = false;
      return;
    }
    try {
      await _dashboardRepository.clearDashboardCache(userId);
      if (mounted) {
        setState(() {
          _showShimmer = true; // Show shimmer during refresh if online
          _cachedData = null;
          _processedCategoryTips = null;
          _dashboardFuture = _initializeDashboardData(userId);
        });
      }
      log('Refreshed data and cleared cache for user $userId', name: 'UserDashboardScreen');
      if (mounted) {
        await Provider.of<PremiumStatusProvider>(context, listen: false).updatePremiumStatus();
      }
    } catch (e, stackTrace) {
      log('Error refreshing data for user $userId: $e', name: 'UserDashboardScreen', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData)),
        );
      }
    } finally {
      _isRefreshing = false;
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

  bool _arePreferencesEqual(UserPreferenceModel? a, UserPreferenceModel? b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    if (a.preferences.length != b.preferences.length) return false;
    for (int i = 0; i < a.preferences.length; i++) {
      if (a.preferences[i].preferenceId != b.preferences[i].preferenceId ||
          a.preferences[i].selectedAt != b.preferences[i].selectedAt) {
        return false;
      }
    }
    return true;
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

    if (!_isConnectivityChecked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userId.isEmpty) {
      log('No user ID found, redirecting to login', name: 'UserDashboardScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      });
      return const SizedBox.shrink();
    }

    if (_cachedData != null && _cachedData!.user != null) {
      return Consumer2<PremiumStatusProvider, UserPreferenceProvider>(
        builder: (context, premiumProvider, preferenceProvider, child) {
          if (!preferenceProvider.isLoading &&
              preferenceProvider.userPreferences != null &&
              !_arePreferencesEqual(_cachedData!.userPreference, preferenceProvider.userPreferences)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              log('User preferences changed, refreshing data', name: 'UserDashboardScreen');
              _refreshData(userId);
            });
          }
          return _buildDashboardContent(context, _cachedData!, userId, theme, isDarkMode);
        },
      );
    }

    return Consumer2<PremiumStatusProvider, UserPreferenceProvider>(
      builder: (context, premiumProvider, preferenceProvider, child) {
        if (_isInitializing && _showShimmer && !_isOffline) {
          return const DashboardShimmer();
        }
        return FutureBuilder<DashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            log(
              'FutureBuilder state: connectionState=${snapshot.connectionState}, '
                  'hasData=${snapshot.hasData}, hasError=${snapshot.hasError}',
              name: 'UserDashboardScreen',
            );

            if (snapshot.connectionState == ConnectionState.waiting && _showShimmer && !_isOffline) {
              return const DashboardShimmer();
            }

            if (snapshot.hasError && !snapshot.hasData) {
              log('FutureBuilder error: ${snapshot.error}', name: 'UserDashboardScreen');
              return _buildErrorView(context, userId, theme, isDarkMode);
            }

            if (snapshot.hasData) {
              final data = snapshot.data!;
              if (data.user != null || _cachedData != null) {
                return _buildDashboardContent(
                  context,
                  data.user != null ? data : (_cachedData ?? _emptyDashboardData()),
                  userId,
                  theme,
                  isDarkMode,
                );
              }
            }

            return _buildErrorView(context, userId, theme, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, String userId, ThemeData theme, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isOffline ? "No internet connection" : "Error loading data",
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

  Widget _buildDashboardContent(
      BuildContext context, DashboardData data, String userId, ThemeData theme, bool isDarkMode) {
    return RepaintBoundary(
      child: RefreshIndicator(
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
            child: _buildDashboardBody(context, data, userId, theme, isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(
      BuildContext context, DashboardData data, String userId, ThemeData theme, bool isDarkMode) {
    if (_processedCategoryTips == null) {
      final userPreferenceIds = data.userPreference?.preferences.map((entry) => entry.preferenceId).toSet() ?? <String>{};
      final filteredCategories = _dashboardUseCase.filterCategories(data.categories, userPreferenceIds);
      _processedCategoryTips = _dashboardUseCase.groupTipsByCategory(data.tips, filteredCategories, userPreferenceIds);
    }

    final userPreferenceIds = data.userPreference?.preferences.map((entry) => entry.preferenceId).toSet() ?? <String>{};
    final filteredCategories = _dashboardUseCase.filterCategories(data.categories, userPreferenceIds);
    final featuredQuotes = _dashboardUseCase.filterFeaturedQuotes(data.tips, userPreferenceIds);
    final categoryTips = _processedCategoryTips ??
        _dashboardUseCase.groupTipsByCategory(data.tips, filteredCategories, userPreferenceIds);
    final validCategories = filteredCategories.where((category) => categoryTips.containsKey(category.categoryId)).toList();

    if (data.user == null) {
      return _buildErrorView(context, userId, theme, isDarkMode);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme, isDarkMode, userId),
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
              RepaintBoundary(
                child: FeaturedQuotesWidget(
                  key: ValueKey('featured_quotes_${featuredQuotes.length}'),
                  featuredTips: featuredQuotes,
                  theme: theme,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
            RepaintBoundary(
              child: DiscoverByCategoryWidget(
                validCategories: validCategories,
                categoryTips: categoryTips,
                theme: theme,
                isDarkMode: isDarkMode,
                onViewAllCategories: widget.onViewAllCategories,
              ),
            ),
            SizedBox(height: 20.h),
            _buildRemindersCard(context, theme, isDarkMode),
            for (var category in validCategories) ...[
              if (categoryTips[category.categoryId]?.isNotEmpty ?? false) ...[
                SizedBox(height: 20.h),
                SectionHeaderWidget(
                  title: category.categoryName,
                  onViewAll: () {
                    Navigator.pushNamed(context, RoutesName.categoryDetailScreen, arguments: category);
                  },
                  viewAllText: AppLocalizations.of(context)!.viewAll,
                  theme: theme,
                  isDarkMode: isDarkMode,
                ),
                SizedBox(height: 1.h),
                RepaintBoundary(
                  child: HorizontalListWidget<TipModel>(
                    items: categoryTips[category.categoryId] ?? [],
                    itemBuilder: (tip) => _buildTipCard(
                      tip,
                      theme,
                      isDarkMode,
                      category.categoryName,
                      categoryTips[category.categoryId] ?? [],
                    ),
                    emptyMessage: AppLocalizations.of(context)!.noDataAvailable,
                    theme: theme,
                    isDarkMode: isDarkMode,
                    placeholderCount: 3,
                  ),
                ),
              ],
            ],
            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDarkMode, String userId) {
    return Row(
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
                      Navigator.pushNamed(context, RoutesName.profileScreen);
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
                                colors: [Color(0xFFD4AF37), Colors.amber.shade500],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.15),
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
                              color: isPremium ? Colors.transparent : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                              width: isPremium ? 0 : 2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.15),
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
                                : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                            backgroundImage: userPhotoUrl != null ? CachedNetworkImageProvider(userPhotoUrl) : null,
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
                            top: -17.h,
                            child: FaIcon(
                              FontAwesomeIcons.crown,
                              size: 24.sp,
                              color: Color(0xFFD4AF37),
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
                          color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600,
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
                color: isDarkMode ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
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
                  Navigator.pushNamed(context, RoutesName.notificationScreen);
                },
              ),
            ),
            Consumer<NotificationCountProvider>(
              builder: (context, notificationProvider, _) {
                if (notificationProvider.unreadCount > 0) {
                  return Positioned(
                    right: -4.w,
                    top: -4.h,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode ? null : Colors.black,
                        gradient: isDarkMode
                            ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                        )
                            : null,
                      ),
                      child: Text(
                        notificationProvider.unreadCount > 9
                            ? '9+'
                            : '${notificationProvider.unreadCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemindersCard(BuildContext context, ThemeData theme, bool isDarkMode) {
    return FadeInUp(
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
              colors: [AppColors.darkSurface, AppColors.darkSurface.withOpacity(0.7)],
            )
                : null,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? AppColors.darkSurface.withOpacity(0.1) : Colors.black.withAlpha(26),
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
              Navigator.pushNamed(context, RoutesName.reminderScreen, arguments: null);
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              height: 120.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                        color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withAlpha(178),
                        semanticLabel: 'Clock icon',
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      RepaintBoundary(
                        child: SizedBox(
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
                                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey.shade600,
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
    );
  }

  Widget _buildTipCard(TipModel tip, ThemeData theme, bool isDarkMode, String categoryName, List<TipModel> featuredTips) {
    if (tip.tipsType == 'quote') {
      return QuoteCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: featuredTips,
      );
    } else if (tip.tipsType == 'audio') {
      return AudioCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: featuredTips,
      );
    } else if (tip.tipsType == 'video') {
      // Check if the video is short (isShort is true or duration < 60 seconds)
      if (tip.isShort || tip.durationInSeconds < 60) {
        return ShortVideoCard(
          tip: tip,
          categoryName: categoryName,
          relatedTips: featuredTips,
        );
      } else {
        return VideoPlayerCard(
          tip: tip,
          categoryName: categoryName,
          featuredTips: featuredTips,
        );
      }
    } else if (tip.tipsType == 'image') {
      return ImageCard(
        tip: tip,
        categoryName: categoryName,
        featuredTips: featuredTips,
      );
    } else {
      return TipCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: featuredTips,
      );
    }
  }
}