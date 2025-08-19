import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import '../../../dashboard/presentation/widgets/quote_card.dart';
import '../../../dashboard/presentation/widgets/tips_card.dart';
import '../../../audioPlayer/presentation/widgets/audio_card.dart';
import '../../../videoPlayer/presentation/widgets/video_player_card.dart';
import '../../../imageViewer/presentation/widgets/image_card.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final DataRepository _dataRepository = DataRepository.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<bool> _isSearchActive = ValueNotifier(false);
  String? _selectedTipsType;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchQuery.value = _searchController.text.toLowerCase();
      });
    });
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
      FocusScope.of(context).unfocus();
    }
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Type',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.primary,
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
                SizedBox(height: 16.h),
                RadioListTile<String?>(
                  title: Text(
                    'All',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  value: null,
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Quote',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  value: 'quote',
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Health Tips',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  value: 'healthTips',
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Tips',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  value: 'tip',
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Audio',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  value: 'audio',
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Video',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  value: 'video',
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  title: Text(
                    'Image',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  value: 'image',
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                SizedBox(height: 8.h),
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
                        _selectedTipsType = null;
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Shimmer.fromColors(
                baseColor: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
                highlightColor: isDarkMode ? AppColors.darkSecondary : AppColors.lightTextPrimary,
                child: Container(
                  height: 160.h,
                  width: 280.w,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: 5,
        ),
      ),
    );
  }

  List<TipModel> _filterTips(List<TipModel> tips) {
    final query = _searchQuery.value;
    final filtered = tips.where((tip) {
      final matchesSearch = query.isEmpty ||
          tip.tipsTitle.toLowerCase().contains(query) ||
          tip.tipsDescription.toLowerCase().contains(query) ||
          tip.tipsType.toLowerCase().contains(query) ||
          tip.tipsAuthor.toLowerCase().contains(query);
      final matchesTipsType = _selectedTipsType == null || tip.tipsType == _selectedTipsType;
      return matchesSearch && matchesTipsType;
    }).toList();
    log('Filtered tips: ${filtered.length}, Premium filtered: ${filtered.where((t) => t.isPremium).length}', name: 'CategoryDetailScreen');
    return filtered;
  }

  Future<Map<String, dynamic>> _fetchCategoryTips() async {
    final user = await _authService.getCurrentUser();
    final canAccessPremium = user != null ? await _dataRepository.canAccessPremiumContent(user.uid) : false;
    final tips = await _dataRepository.getTipsByCategory(
      widget.category.categoryId,
      includePremium: true,
    );
    log('Fetched ${tips.length} tips for category ${widget.category.categoryId}, canAccessPremium: $canAccessPremium',
        name: 'CategoryDetailScreen');
    log('Premium tips: ${tips.where((t) => t.isPremium).map((t) => "${t.tipsId}: ${t.tipsType}").toList()}', name: 'CategoryDetailScreen');
    return {'tips': tips, 'canAccessPremium': canAccessPremium};
  }

  Widget _buildTipCard(TipModel tip, ThemeData theme, bool isDarkMode) {
    final categorySpecificTips = _filterTips((tip.categoryId == widget.category.categoryId) ? [tip] : []);
    if (tip.tipsType == 'quote') {
      return QuoteCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: widget.category.categoryName,
        featuredTips: categorySpecificTips.isNotEmpty ? categorySpecificTips : [tip],
      );
    } else if (tip.tipsType == 'audio') {
      return AudioCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: widget.category.categoryName,
        featuredTips: categorySpecificTips.isNotEmpty ? categorySpecificTips : [tip],
      );
    } else if (tip.tipsType == 'video') {
      return VideoPlayerCard(
        tip: tip,
        categoryName: widget.category.categoryName,
        featuredTips: categorySpecificTips.isNotEmpty ? categorySpecificTips : [tip],
      );
    } else if (tip.tipsType == 'image') {
      return ImageCard(
        tip: tip,
        categoryName: widget.category.categoryName,
        featuredTips: categorySpecificTips.isNotEmpty ? categorySpecificTips : [tip],
      );
    } else {
      return TipCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: widget.category.categoryName,
        featuredTips: categorySpecificTips.isNotEmpty ? categorySpecificTips : [tip],
      );
    }
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
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
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
            body: SafeArea(
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
                                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextPrimary,
                                      )
                                          : Icon(
                                        Icons.chevron_left,
                                        size: 30.sp,
                                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextPrimary,
                                      ),
                                      onPressed: () {
                                        if (isSearchActive) {
                                          _toggleSearch();
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      },
                                      tooltip: isSearchActive ? 'Close Search' : 'Back',
                                    ),
                                  ),
                                  Expanded(
                                    child: isSearchActive
                                        ? TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 16.sp,
                                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search ${widget.category.categoryName}...',
                                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 16.sp,
                                          color: isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
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
                                                FocusScope.of(context).unfocus();
                                              },
                                            )
                                                : const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                    )
                                        : Row(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              widget.category.categoryName,
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: SvgPicture.asset(
                                            'assets/icons/svg/ic_search.svg',
                                            width: 24.sp,
                                            height: 24.sp,
                                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextPrimary,
                                          ),
                                          onPressed: _toggleSearch,
                                          tooltip: 'Search',
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isSearchActive)
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'assets/icons/svg/ic_filter.svg',
                                        width: 24.sp,
                                        height: 24.sp,
                                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextPrimary,
                                      ),
                                      onPressed: () => _showFilterDialog(context),
                                      tooltip: 'Filter Content',
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
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    sliver: ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, searchQuery, child) {
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _fetchCategoryTips(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildShimmerUI(context);
                            }

                            if (snapshot.hasError) {
                              log('Error loading tips: ${snapshot.error}', name: 'CategoryDetailScreen');
                              return SliverToBoxAdapter(
                                child: Center(
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
                                        'Error loading tips',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 16.sp,
                                          fontFamily: 'Poppins',
                                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8.h),
                                      ElevatedButton(
                                        onPressed: () => setState(() {}),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                        ),
                                        child: Text(
                                          'Retry',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final data = snapshot.data ?? {'tips': [], 'canAccessPremium': false};
                            final tips = data['tips'] as List<TipModel>;
                            final canAccessPremium = data['canAccessPremium'] as bool;
                            final filteredTips = _filterTips(tips);

                            if (filteredTips.isEmpty) {
                              final hasHealthTips = tips.any((tip) => tip.tipsType == 'healthTips');
                              final hasTips = tips.any((tip) => tip.tipsType == 'tip');
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
                                        hasHealthTips || hasTips
                                            ? 'No tips match your filter or search'
                                            : 'No tips available in this category',
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
                                    child: _buildTipCard(tip, theme, isDarkMode),
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
            ),
          ),
        ),
      ),
    );
  }
}