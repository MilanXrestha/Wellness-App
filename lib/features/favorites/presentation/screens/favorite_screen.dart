import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/features/dashboard/presentation/widgets/quote_card.dart';
import 'package:wellness_app/features/dashboard/presentation/widgets/tips_card.dart';
import 'package:wellness_app/features/audioPlayer/presentation/widgets/audio_card.dart';
import 'package:wellness_app/features/videoPlayer/presentation/widgets/video_player_card.dart';
import 'package:wellness_app/features/imageViewer/presentation/widgets/image_card.dart';
import 'package:wellness_app/features/videoPlayer/presentation/widgets/short_video_card.dart';

class FavoriteScreen extends StatefulWidget {
  final ValueChanged<bool>? onSearchActiveChanged;

  const FavoriteScreen({super.key, this.onSearchActiveChanged});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<bool> _isSearchActive = ValueNotifier(false);
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedFilter;
  Timer? _debounce;
  bool _isLoading = true;
  String? _userId;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchQuery.value = _searchController.text.toLowerCase();
      });
    });
    _searchFocusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;

      if (result != ConnectivityResult.none && _userId != null) {
        log(
          'Network available, syncing pending operations',
          name: 'FavoriteScreen',
        );

        // Use the syncFavorites method which handles both operations
        Provider.of<FavoritesProvider>(
          context,
          listen: false,
        ).syncFavorites(_userId!);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _userId != null) {
      log('App resumed, syncing pending operations', name: 'FavoriteScreen');
      Provider.of<FavoritesProvider>(
        context,
        listen: false,
      ).syncFavorites(_userId!);
    }
  }

  Future<void> _checkAuthState() async {
    final authService = AuthService();
    final user = authService.getCurrentUser();
    if (user == null) {
      log(
        'No authenticated user found, redirecting to login',
        name: 'FavoriteScreen',
      );
      Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      return;
    }

    _userId = user.uid;
    log('Authenticated user found: $_userId', name: 'FavoriteScreen');
    await _refreshFavorites();
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final provider = Provider.of<FavoritesProvider>(context, listen: false);
      await provider.loadFavorites(_userId!);
      if (provider.favorites.isEmpty && await _isOnline()) {
        log(
          'No favorites found for user $_userId, triggering sync',
          name: 'FavoriteScreen',
        );
        await DataRepository.instance.syncAllData(_userId!);
        await provider.loadFavorites(_userId!);
      }
    } catch (e) {
      log('Error loading favorites: $e', name: 'FavoriteScreen');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus != _isSearchActive.value) {
      setState(() {
        _isSearchActive.value = _searchFocusNode.hasFocus;
        widget.onSearchActiveChanged?.call(!_searchFocusNode.hasFocus);
      });
      log(
        'Search focus changed: ${_searchFocusNode.hasFocus}',
        name: 'FavoriteScreen',
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive.value = !_isSearchActive.value;
      widget.onSearchActiveChanged?.call(!_isSearchActive.value);
      if (!_isSearchActive.value) {
        _searchController.clear();
        _searchQuery.value = '';
        FocusScope.of(context).unfocus();
        log('Search deactivated via toggle', name: 'FavoriteScreen');
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
          log(
            'Search activated via toggle, opening keyboard',
            name: 'FavoriteScreen',
          );
        });
      }
    });
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          backgroundColor: isDarkMode
              ? AppColors.darkSurface
              : AppColors.lightBackground,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Favorites',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/svg/ic_clear.svg',
                        width: 22.sp,
                        height: 22.sp,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Select Content Type',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                RadioListTile<String?>(
                  title: Text(
                    'All',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: null,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Quote',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: 'quote',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Tip',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: 'tip',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Audio',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: 'audio',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Video',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: 'video',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Shorts',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: 'shorts',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Image',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: 'image',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    icon: SvgPicture.asset(
                      'assets/icons/svg/ic_trash.svg',
                      width: 16.sp,
                      height: 16.sp,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Clear Filter',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.error,
                        fontSize: 14.sp,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFilter = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerUI(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ).copyWith(bottom: 80.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Shimmer.fromColors(
              baseColor: isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.lightBackground,
              highlightColor: isDarkMode
                  ? AppColors.darkSecondary
                  : AppColors.lightTextPrimary,
              child: Container(
                width: double.infinity,
                height: 160.h,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          );
        }, childCount: 5),
      ),
    );
  }

  List<TipModel> _filterTips(List<TipModel> tips) {
    final query = _searchQuery.value;

    if (_selectedFilter == 'shorts') {
      return tips.where((tip) {
        final isShort =
            tip.tipsType == 'video' &&
            (tip.isShort || tip.durationInSeconds < 60);
        final matchesSearch =
            query.isEmpty ||
            tip.tipsTitle.toLowerCase().contains(query) ||
            tip.tipsAuthor.toLowerCase().contains(query);
        return isShort && matchesSearch;
      }).toList();
    } else if (_selectedFilter == 'video') {
      return tips.where((tip) {
        final isRegularVideo =
            tip.tipsType == 'video' &&
            !(tip.isShort || tip.durationInSeconds < 60);
        final matchesSearch =
            query.isEmpty ||
            tip.tipsTitle.toLowerCase().contains(query) ||
            tip.tipsAuthor.toLowerCase().contains(query);
        return isRegularVideo && matchesSearch;
      }).toList();
    } else {
      return tips.where((tip) {
        final matchesSearch =
            query.isEmpty ||
            tip.tipsTitle.toLowerCase().contains(query) ||
            tip.tipsAuthor.toLowerCase().contains(query);
        final matchesFilter =
            _selectedFilter == null || tip.tipsType == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    }
  }

  List<TipModel> _getSimilarContentList(
    TipModel currentTip,
    List<TipModel> allTips,
  ) {
    if (currentTip.tipsType == 'video' &&
        (currentTip.isShort || currentTip.durationInSeconds < 60)) {
      return allTips
          .where(
            (tip) =>
                tip.tipsType == 'video' &&
                (tip.isShort || tip.durationInSeconds < 60),
          )
          .toList();
    } else if (currentTip.tipsType == 'video') {
      return allTips
          .where(
            (tip) =>
                tip.tipsType == 'video' &&
                !(tip.isShort || tip.durationInSeconds < 60),
          )
          .toList();
    } else {
      return allTips
          .where((tip) => tip.tipsType == currentTip.tipsType)
          .toList();
    }
  }

  Widget _buildTipCard(
    TipModel tip,
    ThemeData theme,
    bool isDarkMode,
    List<TipModel> allFavoriteTips,
  ) {
    final categoryName = 'Favorites';
    final similarTips = _getSimilarContentList(tip, allFavoriteTips);

    if (tip.tipsType == 'quote') {
      return QuoteCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: similarTips,
      );
    } else if (tip.tipsType == 'audio') {
      return AudioCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: similarTips,
      );
    } else if (tip.tipsType == 'video') {
      if (tip.isShort || tip.durationInSeconds < 60) {
        return ShortVideoCard(
          tip: tip,
          categoryName: categoryName,
          relatedTips: similarTips,
        );
      } else {
        return VideoPlayerCard(
          tip: tip,
          categoryName: categoryName,
          featuredTips: similarTips,
        );
      }
    } else if (tip.tipsType == 'image') {
      return ImageCard(
        tip: tip,
        categoryName: categoryName,
        featuredTips: similarTips,
      );
    } else {
      return TipCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: similarTips,
      );
    }
  }

  Widget _buildSectionHeader(String title, ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDarkMode
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _organizeContentByType(
    List<TipModel> tips,
    ThemeData theme,
    bool isDarkMode,
  ) {
    final List<Widget> organizedContent = [];
    List<TipModel> quotes = [];
    List<TipModel> tipItems = [];
    List<TipModel> audioItems = [];
    List<TipModel> regularVideos = [];
    List<TipModel> shorts = [];
    List<TipModel> imageItems = [];
    List<TipModel> others = [];

    for (var tip in tips) {
      if (tip.tipsType == 'video') {
        if (tip.isShort || tip.durationInSeconds < 60) {
          shorts.add(tip);
        } else {
          regularVideos.add(tip);
        }
      } else if (tip.tipsType == 'quote') {
        quotes.add(tip);
      } else if (tip.tipsType == 'tip') {
        tipItems.add(tip);
      } else if (tip.tipsType == 'audio') {
        audioItems.add(tip);
      } else if (tip.tipsType == 'image') {
        imageItems.add(tip);
      } else {
        others.add(tip);
      }
    }

    if (quotes.isNotEmpty) {
      organizedContent.add(_buildSectionHeader('Quotes', theme, isDarkMode));
      for (var tip in quotes) {
        organizedContent.add(
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildTipCard(tip, theme, isDarkMode, tips),
          ),
        );
      }
    }

    if (tipItems.isNotEmpty) {
      organizedContent.add(_buildSectionHeader('Tips', theme, isDarkMode));
      for (var tip in tipItems) {
        organizedContent.add(
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildTipCard(tip, theme, isDarkMode, tips),
          ),
        );
      }
    }

    if (audioItems.isNotEmpty) {
      organizedContent.add(_buildSectionHeader('Audio', theme, isDarkMode));
      for (var tip in audioItems) {
        organizedContent.add(
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildTipCard(tip, theme, isDarkMode, tips),
          ),
        );
      }
    }

    if (regularVideos.isNotEmpty) {
      organizedContent.add(_buildSectionHeader('Videos', theme, isDarkMode));
      for (var tip in regularVideos) {
        organizedContent.add(
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildTipCard(tip, theme, isDarkMode, tips),
          ),
        );
      }
    }

    if (shorts.isNotEmpty) {
      organizedContent.add(_buildSectionHeader('Shorts', theme, isDarkMode));
      for (int i = 0; i < shorts.length; i += 2) {
        if (i + 1 < shorts.length) {
          organizedContent.add(
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Flexible(
                    child: _buildTipCard(shorts[i], theme, isDarkMode, tips),
                  ),
                  SizedBox(width: 12.w),
                  Flexible(
                    child: _buildTipCard(
                      shorts[i + 1],
                      theme,
                      isDarkMode,
                      tips,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          organizedContent.add(
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Flexible(
                    child: _buildTipCard(shorts[i], theme, isDarkMode, tips),
                  ),
                  SizedBox(width: 12.w),
                  Flexible(child: Container()),
                ],
              ),
            ),
          );
        }
      }
    }

    if (imageItems.isNotEmpty) {
      organizedContent.add(_buildSectionHeader('Images', theme, isDarkMode));
      for (int i = 0; i < imageItems.length; i += 2) {
        if (i + 1 < imageItems.length) {
          organizedContent.add(
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Flexible(
                    child: _buildTipCard(
                      imageItems[i],
                      theme,
                      isDarkMode,
                      tips,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Flexible(
                    child: _buildTipCard(
                      imageItems[i + 1],
                      theme,
                      isDarkMode,
                      tips,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          organizedContent.add(
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Flexible(
                    child: _buildTipCard(
                      imageItems[i],
                      theme,
                      isDarkMode,
                      tips,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Flexible(child: Container()),
                ],
              ),
            ),
          );
        }
      }
    }

    if (others.isNotEmpty) {
      organizedContent.add(_buildSectionHeader('Other', theme, isDarkMode));
      for (var tip in others) {
        organizedContent.add(
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildTipCard(tip, theme, isDarkMode, tips),
          ),
        );
      }
    }

    return organizedContent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_isSearchActive.value) {
          _toggleSearch();
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () {
          if (_isSearchActive.value) {
            _toggleSearch();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        pinned: true,
                        floating: true,
                        snap: true,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        expandedHeight: 64.h,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _isSearchActive,
                              builder: (context, isSearchActive, child) {
                                return Container(
                                  height: 56.h,
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Color(0xFF121212)
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(24.r),
                                    boxShadow: isDarkMode
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: AppColors.shadow,
                                              blurRadius: 6.r,
                                              offset: Offset(0, 2.h),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 12.w),
                                        child: IconButton(
                                          icon: isSearchActive
                                              ? Icon(
                                                  Icons.chevron_left,
                                                  size: 30.sp,
                                                  color: isDarkMode
                                                      ? AppColors
                                                            .darkTextSecondary
                                                      : AppColors
                                                            .lightTextPrimary,
                                                )
                                              : SvgPicture.asset(
                                                  'assets/icons/svg/ic_search.svg',
                                                  width: 24.sp,
                                                  height: 24.sp,
                                                  color: isDarkMode
                                                      ? AppColors
                                                            .darkTextSecondary
                                                      : AppColors
                                                            .lightTextPrimary,
                                                ),
                                          onPressed: _toggleSearch,
                                          tooltip: isSearchActive
                                              ? 'Close Search'
                                              : 'Search',
                                        ),
                                      ),
                                      Expanded(
                                        child: isSearchActive
                                            ? TextField(
                                                controller: _searchController,
                                                focusNode: _searchFocusNode,
                                                enabled: isSearchActive,
                                                autofocus: isSearchActive,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontSize: 16.sp,
                                                      color: isDarkMode
                                                          ? AppColors
                                                                .darkTextPrimary
                                                          : AppColors
                                                                .lightTextPrimary,
                                                    ),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Search favorites...',
                                                  hintStyle: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontSize: 16.sp,
                                                        color: isDarkMode
                                                            ? AppColors
                                                                  .darkTextHint
                                                            : AppColors
                                                                  .lightTextHint,
                                                      ),
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  disabledBorder:
                                                      InputBorder.none,
                                                  filled: false,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        vertical: 12.h,
                                                        horizontal: 4.w,
                                                      ),
                                                  suffixIcon: ValueListenableBuilder<String>(
                                                    valueListenable:
                                                        _searchQuery,
                                                    builder: (context, searchQuery, child) {
                                                      return searchQuery
                                                              .isNotEmpty
                                                          ? IconButton(
                                                              icon: SvgPicture.asset(
                                                                'assets/icons/svg/ic_clear.svg',
                                                                width: 20.sp,
                                                                height: 20.sp,
                                                                color:
                                                                    isDarkMode
                                                                    ? AppColors
                                                                          .darkTextSecondary
                                                                    : AppColors
                                                                          .lightTextPrimary,
                                                              ),
                                                              onPressed: () {
                                                                _searchController
                                                                    .clear();
                                                                _searchQuery
                                                                        .value =
                                                                    '';
                                                              },
                                                            )
                                                          : const SizedBox.shrink();
                                                    },
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  'Favorites',
                                                  style: theme
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        color: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                        fontSize: 18.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                      ),
                                      if (!isSearchActive)
                                        IconButton(
                                          icon: SvgPicture.asset(
                                            'assets/icons/svg/ic_filter.svg',
                                            width: 24.sp,
                                            height: 24.sp,
                                            color: isDarkMode
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextPrimary,
                                          ),
                                          onPressed: () =>
                                              _showFilterDialog(context),
                                          tooltip: 'Filter Favorites',
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ).copyWith(bottom: 80.h),
                        sliver: _isLoading
                            ? _buildShimmerUI(context)
                            : Consumer<FavoritesProvider>(
                                builder: (context, provider, child) {
                                  if (provider.error != null) {
                                    return SliverToBoxAdapter(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Lottie.asset(
                                            'assets/animations/no_fav.json',
                                            width: 300.w,
                                            height: 300.h,
                                            fit: BoxFit.contain,
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'Error loading favorites: ${provider.error}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontSize: 16.sp,
                                                  color: isDarkMode
                                                      ? AppColors
                                                            .darkTextSecondary
                                                      : AppColors
                                                            .lightTextSecondary,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 8.h),
                                          ElevatedButton(
                                            onPressed: () {
                                              _refreshFavorites();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                            ),
                                            child: Text(
                                              'Retry',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontSize: 14.sp,
                                                    color: AppColors
                                                        .lightBackground,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (provider.favorites.isEmpty) {
                                    return SliverToBoxAdapter(
                                      child: Container(
                                        padding: EdgeInsets.all(10.w),
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5.h,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Lottie.asset(
                                              'assets/animations/no_fav.json',
                                              width: 300.w,
                                              height: 300.h,
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(height: 5.h),
                                            Text(
                                              'No favorite tips available.\nTo add to favorites, please click the heart icon.',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontSize: 16.sp,
                                                    color: isDarkMode
                                                        ? AppColors
                                                              .darkTextSecondary
                                                        : AppColors
                                                              .lightTextSecondary,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // Get tips directly from provider's cache
                                  final favoriteTips = provider
                                      .getFavoriteTips();

                                  if (favoriteTips.isEmpty) {
                                    // If cache is empty but we have favorites, show loading
                                    return _buildShimmerUI(context);
                                  }

                                  final filteredTips = _filterTips(
                                    favoriteTips,
                                  );

                                  if (filteredTips.isEmpty) {
                                    return SliverToBoxAdapter(
                                      child: Container(
                                        padding: EdgeInsets.all(10.w),
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5.h,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Lottie.asset(
                                              'assets/animations/no_fav.json',
                                              width: 300.w,
                                              height: 300.h,
                                              fit: BoxFit.contain,
                                            ),
                                            SizedBox(height: 5.h),
                                            Text(
                                              'No matching favorites found for the current filter.',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontSize: 16.sp,
                                                    color: isDarkMode
                                                        ? AppColors
                                                              .darkTextSecondary
                                                        : AppColors
                                                              .lightTextSecondary,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final organizedContent =
                                      _organizeContentByType(
                                        filteredTips,
                                        theme,
                                        isDarkMode,
                                      );

                                  return SliverList(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      return organizedContent[index];
                                    }, childCount: organizedContent.length),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchQuery.dispose();
    _isSearchActive.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
  }
}
