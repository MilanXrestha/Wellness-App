import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_generator.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/services/data_repository.dart';

import '../../../dashboard/presentation/widgets/quote_card.dart';
import '../../../dashboard/presentation/widgets/tips_card.dart';


class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<bool> _isSearchActive = ValueNotifier(false);
  String? _selectedFilter;
  Timer? _debounce;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchQuery.value = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    final authService = AuthService();
    final user = authService.getCurrentUser();
    if (user == null) {
      log('No authenticated user found, redirecting to login', name: 'FavoriteScreen');
      Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      return;
    }

    _userId = user.uid;
    log('Authenticated user found: $_userId', name: 'FavoriteScreen');
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<FavoritesProvider>(context, listen: false);
      await provider.loadFavorites(_userId!);
      if (provider.favorites.isEmpty) {
        log('No favorites found for user $_userId, triggering sync', name: 'FavoriteScreen');
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchQuery.dispose();
    _isSearchActive.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    _isSearchActive.value = !_isSearchActive.value;
    if (!_isSearchActive.value) {
      _searchController.clear();
      _searchQuery.value = '';
    }
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
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
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/svg/ic_clear.svg',
                        width: 22.sp,
                        height: 22.sp,
                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Select Content Type',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                RadioListTile<String?>(
                  title: Text(
                    'All',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                  activeColor: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
                RadioListTile<String>(
                  title: Text(
                    'Quote',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                  activeColor: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
                RadioListTile<String>(
                  title: Text(
                    'Tip',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                  activeColor: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
                RadioListTile<String>(
                  title: Text(
                    'Health Tips',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                  value: 'healthTips',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h).copyWith(bottom: 80.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Shimmer.fromColors(
              baseColor: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
              highlightColor: isDarkMode ? AppColors.darkSecondary : AppColors.lightTextPrimary,
              child: Container(
                width: 280.w,
                height: 160.h,
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
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
    return tips.where((tip) {
      final matchesSearch =
          query.isEmpty ||
              tip.tipsTitle.toLowerCase().contains(query) ||
              tip.tipsAuthor.toLowerCase().contains(query);
      final matchesFilter =
          _selectedFilter == null ||
              (_selectedFilter == 'quote' && tip.tipsType == 'quote') ||
              (_selectedFilter == 'tip' && tip.tipsType == 'tip') ||
              (_selectedFilter == 'healthTips' && tip.tipsType == 'healthTips');
      return matchesSearch && matchesFilter;
    }).toList();
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: CustomScrollView(
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
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _isSearchActive,
                              builder: (context, isSearchActive, child) {
                                return Container(
                                  height: 56.h,
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(24.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 6.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(left: 12.w),
                                        child: IconButton(
                                          icon: isSearchActive
                                              ? Icon(
                                            Icons.chevron_left,
                                            size: 30.sp,
                                            color: isDarkMode
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextPrimary,
                                          )
                                              : SvgPicture.asset(
                                            'assets/icons/svg/ic_search.svg',
                                            width: 24.sp,
                                            height: 24.sp,
                                            color: isDarkMode
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextPrimary,
                                          ),
                                          onPressed: _toggleSearch,
                                          tooltip: isSearchActive ? 'Close Search' : 'Search',
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          autofocus: isSearchActive,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 16.sp,
                                            color: isDarkMode
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Search favorites...',
                                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: 16.sp,
                                              color: isDarkMode
                                                  ? AppColors.darkTextHint
                                                  : AppColors.lightTextHint,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: false,
                                            contentPadding:
                                            EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                                            suffixIcon: ValueListenableBuilder<String>(
                                              valueListenable: _searchQuery,
                                              builder: (context, searchQuery, child) {
                                                return searchQuery.isNotEmpty
                                                    ? IconButton(
                                                  icon: SvgPicture.asset(
                                                    'assets/icons/svg/ic_clear.svg',
                                                    width: 20.sp,
                                                    height: 20.sp,
                                                    color: isDarkMode
                                                        ? AppColors.darkTextSecondary
                                                        : AppColors.lightTextPrimary,
                                                  ),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    _searchQuery.value = '';
                                                  },
                                                )
                                                    : const SizedBox.shrink();
                                              },
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
                                          onPressed: () => _showFilterDialog(context),
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
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h).copyWith(bottom: 80.h),
                        sliver: _isLoading
                            ? _buildShimmerUI(context)
                            : Consumer<FavoritesProvider>(
                          builder: (context, provider, child) {
                            if (provider.error != null) {
                              return SliverToBoxAdapter(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 16.sp,
                                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8.h),
                                    ElevatedButton(
                                      onPressed: () {
                                        provider.loadFavorites(_userId!);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontSize: 14.sp,
                                          color: AppColors.lightBackground,
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
                                  margin: EdgeInsets.symmetric(vertical: 5.h),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 16.sp,
                                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return FutureBuilder<List<TipModel>>(
                              future: Future.wait(
                                provider.favorites.map((favorite) async {
                                  final tip = await DataRepository.instance.getTip(favorite.tipId);
                                  return tip; // No premium check for favorites
                                }).toList(),
                              ).then((tips) => tips.where((tip) => tip != null).cast<TipModel>().toList()),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return _buildShimmerUI(context);
                                }
                                if (snapshot.hasError) {
                                  log('Error loading favorites: ${snapshot.error}', name: 'FavoriteScreen');
                                  return SliverToBoxAdapter(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Lottie.asset(
                                          'assets/animations/no_fav.json',
                                          width: 300.w,
                                          height: 300.h,
                                          fit: BoxFit.contain,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Error loading favorites',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 16.sp,
                                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8.h),
                                        ElevatedButton(
                                          onPressed: () {
                                            provider.loadFavorites(_userId!);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          child: Text(
                                            'Retry',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontSize: 14.sp,
                                              color: AppColors.lightBackground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                final favoriteTips = snapshot.data ?? [];
                                final filteredTips = _filterTips(favoriteTips);
                                if (filteredTips.isEmpty) {
                                  return SliverToBoxAdapter(
                                    child: Container(
                                      padding: EdgeInsets.all(10.w),
                                      margin: EdgeInsets.symmetric(vertical: 5.h),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
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
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: 16.sp,
                                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                      final tip = filteredTips[index];
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 12.h),
                                        child: tip.tipsType == 'quote'
                                            ? QuoteCard(
                                          tip: tip,
                                          theme: theme,
                                          isDarkMode: isDarkMode,
                                          categoryName: 'Favorites',
                                          featuredTips: filteredTips,
                                        )
                                            : TipCard(
                                          tip: tip,
                                          theme: theme,
                                          isDarkMode: isDarkMode,
                                          categoryName: 'Favorites',
                                          featuredTips: filteredTips,
                                        ),
                                      );
                                    },
                                    childCount: filteredTips.length,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}