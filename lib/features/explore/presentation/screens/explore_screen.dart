import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'dart:developer';

import '../../../dashboard/presentation/widgets/quote_card.dart';
import '../../../dashboard/presentation/widgets/tips_card.dart';
import '../../../audioPlayer/presentation/widgets/audio_card.dart';
import '../../../videoPlayer/presentation/widgets/video_player_card.dart';
import '../../../imageViewer/presentation/widgets/image_card.dart';

class FilteredContent extends StatelessWidget {
  final String searchQuery;
  final String? selectedCategoryId;
  final String? selectedTipsType;
  final List<CategoryModel> categories;
  final List<TipModel> tips;
  final ValueChanged<String?> onCategorySelected;
  final bool canAccessPremium;

  const FilteredContent({
    super.key,
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.selectedTipsType,
    required this.categories,
    required this.tips,
    required this.onCategorySelected,
    required this.canAccessPremium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final categoryMap = {
      for (var category in categories)
        category.categoryId: category.categoryName,
    };

    final filteredTips = tips.where((tip) {
      final matchesSearch =
          searchQuery.isEmpty ||
          tip.tipsTitle.toLowerCase().contains(searchQuery) ||
          tip.tipsDescription.toLowerCase().contains(searchQuery) ||
          tip.tipsType.toLowerCase().contains(searchQuery) ||
          tip.tipsAuthor.toLowerCase().contains(searchQuery) ||
          (categoryMap[tip.categoryId]?.toLowerCase().contains(searchQuery) ??
              false);
      final matchesCategory =
          selectedCategoryId == null || tip.categoryId == selectedCategoryId;
      final matchesTipsType =
          selectedTipsType == null || tip.tipsType == selectedTipsType;
      return matchesSearch && matchesCategory && matchesTipsType;
    }).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          if (filteredTips.isEmpty)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/no_data.json',
                    width: 250.w,
                    height: 250.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No content found. Try adjusting your search or filters.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextPrimary,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            )
          else
            ...categories.map((category) {
              final categoryTips = filteredTips
                  .where((tip) => tip.categoryId == category.categoryId)
                  .take(10)
                  .toList();

              if (categoryTips.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.categoryName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontSize: 18.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            log(
                              'View All for ${category.categoryName}',
                              name: 'FilteredContent',
                            );
                            Navigator.pushNamed(
                              context,
                              RoutesName.categoryDetailScreen,
                              arguments: category,
                            );
                          },
                          child: Text(
                            'View All',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: isDarkMode
                                  ? AppColors.primary
                                  : AppColors.lightTextPrimary,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categoryTips.map((tip) {
                          return Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: _buildTipCard(
                              tip,
                              category.categoryName,
                              filteredTips,
                              theme,
                              isDarkMode,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    TipModel tip,
    String categoryName,
    List<TipModel> featuredTips,
    ThemeData theme,
    bool isDarkMode,
  ) {
    final categorySpecificTips = featuredTips
        .where((t) => t.categoryId == tip.categoryId)
        .toList();
    if (tip.tipsType == 'quote') {
      return QuoteCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: categorySpecificTips,
      );
    } else if (tip.tipsType == 'audio') {
      return AudioCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: categorySpecificTips,
      );
    } else if (tip.tipsType == 'video') {
      return VideoPlayerCard(
        tip: tip,
        categoryName: categoryName,
        featuredTips: categorySpecificTips,
      );
    } else if (tip.tipsType == 'image') {
      return ImageCard(
        tip: tip,
        categoryName: categoryName,
        featuredTips: categorySpecificTips,
      );
    } else {
      return TipCard(
        tip: tip,
        theme: theme,
        isDarkMode: isDarkMode,
        categoryName: categoryName,
        featuredTips: categorySpecificTips,
      );
    }
  }
}

class ExploreScreen extends StatefulWidget {
  final ValueChanged<bool>? onSearchActiveChanged;

  const ExploreScreen({super.key, this.onSearchActiveChanged});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<bool> _isSearchActive = ValueNotifier(false);
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedCategoryId;
  String? _selectedTipsType;
  List<CategoryModel> _categories = [];
  Future<Map<String, dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _fetchData();
  }

  void _fetchData() {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isEmpty) {
      log('No user ID found in _fetchData', name: 'ExploreScreen');
      return;
    }
    _dataFuture =
        Future.wait([
              DataRepository.instance.getCategories(),
              DataRepository.instance.getTips(includePremium: true),
              DataRepository.instance.canAccessPremiumContent(userId),
            ])
            .then((results) async {
              final categories = results[0] as List<CategoryModel>;
              final tips = results[1] as List<TipModel>;
              final canAccessPremium = results[2] as bool;

              setState(() {
                _categories = categories;
              });

              return {
                'categories': categories,
                'tips': tips,
                'canAccessPremium': canAccessPremium,
              };
            })
            .catchError((e, stackTrace) {
              log(
                'Error fetching data: $e',
                name: 'ExploreScreen',
                stackTrace: stackTrace,
              );
              throw e;
            });
  }

  void _onSearchTextChanged() {
    _searchQuery.value = _searchController.text.toLowerCase();
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus != _isSearchActive.value) {
      setState(() {
        _isSearchActive.value = _searchFocusNode.hasFocus;
        widget.onSearchActiveChanged?.call(!_searchFocusNode.hasFocus);
      });
      log(
        'Search focus changed: ${_searchFocusNode.hasFocus}',
        name: 'ExploreScreen',
      );
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
                      'Filter Content',
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
                        width: 24.sp,
                        height: 24.sp,
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
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
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
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
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
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
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
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
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
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SizedBox(height: 6.h),
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
                  groupValue: _selectedTipsType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTipsType = value;
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
                      'assets/icons/svg/ic_delete.svg',
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

  void _toggleSearch() {
    setState(() {
      _isSearchActive.value = !_isSearchActive.value;
      widget.onSearchActiveChanged?.call(!_isSearchActive.value);
      if (!_isSearchActive.value) {
        _searchController.clear();
        _searchQuery.value = '';
        FocusScope.of(context).unfocus();
        log('Search deactivated via toggle', name: 'ExploreScreen');
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
          log(
            'Search activated via toggle, opening keyboard',
            name: 'ExploreScreen',
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _searchQuery.dispose();
    _isSearchActive.dispose();
    super.dispose();
  }

  Widget _buildChipList(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ChoiceChip(
                  label: Text(
                    'All',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _selectedCategoryId == null
                          ? AppColors.lightBackground
                          : isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  selected: _selectedCategoryId == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                    }
                  },
                  selectedColor: isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary,
                  backgroundColor: isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: isDarkMode
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.lightTextPrimary.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  showCheckmark: false,
                ),
              ),
              if (_categories.isEmpty)
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Shimmer.fromColors(
                      baseColor: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.lightBackground,
                      highlightColor: isDarkMode
                          ? AppColors.darkSecondary
                          : AppColors.lightTextPrimary,
                      child: Container(
                        width: 100.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkSurface
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                  ),
                )
              else
                ..._categories.map((category) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(
                        category.categoryName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _selectedCategoryId == category.categoryId
                              ? AppColors.lightBackground
                              : isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      selected: _selectedCategoryId == category.categoryId,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategoryId = category.categoryId;
                          });
                        }
                      },
                      selectedColor: isDarkMode
                          ? AppColors.primary
                          : AppColors.lightTextPrimary,
                      backgroundColor: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.lightBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(
                          color: isDarkMode
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.lightTextPrimary.withOpacity(0.3),
                          width: 1.w,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerUI(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Shimmer.fromColors(
                          baseColor: isDarkMode
                              ? AppColors.darkSurface
                              : AppColors.lightBackground,
                          highlightColor: isDarkMode
                              ? AppColors.darkSecondary
                              : AppColors.lightTextPrimary,
                          child: Container(
                            width: 150.w,
                            height: 18.h,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkSurface
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                        Shimmer.fromColors(
                          baseColor: isDarkMode
                              ? AppColors.darkSurface
                              : AppColors.lightBackground,
                          highlightColor: isDarkMode
                              ? AppColors.darkSecondary
                              : AppColors.lightTextPrimary,
                          child: Container(
                            width: 60.w,
                            height: 14.h,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkSurface
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          5,
                          (index) => Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: Shimmer.fromColors(
                              baseColor: isDarkMode
                                  ? AppColors.darkSurface
                                  : AppColors.lightBackground,
                              highlightColor: isDarkMode
                                  ? AppColors.darkSecondary
                                  : AppColors.lightTextPrimary,
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? AppColors.darkTextHint
                                        : AppColors.lightTextHint,
                                    width: 1.w,
                                  ),
                                ),
                                child: Container(
                                  width: 260.w,
                                  height: 220.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final userId = _authService.getCurrentUser()?.uid ?? '';

    if (userId.isEmpty) {
      log('No user ID found, redirecting to login', name: 'ExploreScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      });
      return const SizedBox.shrink();
    }

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
                                    ? [] // no shadow in dark mode
                                    : [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 6.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: isDarkMode
                                                      ? AppColors
                                                            .darkTextPrimary
                                                      : AppColors
                                                            .lightTextPrimary,
                                                ),
                                            decoration: InputDecoration(
                                              hintText: 'Search content...',
                                              hintStyle: theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: isDarkMode
                                                        ? AppColors.darkTextHint
                                                        : AppColors
                                                              .lightTextHint,
                                                  ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              filled: false,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 12.h,
                                                    horizontal: 4.w,
                                                  ),
                                              suffixIcon: ValueListenableBuilder<String>(
                                                valueListenable: _searchQuery,
                                                builder: (context, searchQuery, child) {
                                                  return searchQuery.isNotEmpty
                                                      ? IconButton(
                                                          icon: SvgPicture.asset(
                                                            'assets/icons/svg/ic_clear.svg',
                                                            width: 24.sp,
                                                            height: 24.sp,
                                                            color: isDarkMode
                                                                ? AppColors
                                                                      .darkTextSecondary
                                                                : AppColors
                                                                      .lightTextPrimary,
                                                          ),
                                                          onPressed: () {
                                                            _searchController
                                                                .clear();
                                                            _searchQuery.value =
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
                                              'Explore',
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
                                                    fontWeight: FontWeight.bold,
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
                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  SliverToBoxAdapter(child: _buildChipList(context)),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: FutureBuilder<Map<String, dynamic>>(
                        future: _dataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            log('FutureBuilder waiting', name: 'ExploreScreen');
                            return _buildShimmerUI(context);
                          }

                          if (snapshot.hasError || !snapshot.hasData) {
                            log(
                              'FutureBuilder error: ${snapshot.error}',
                              name: 'ExploreScreen',
                            );
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/animations/no_data.json',
                                  width: 250.w,
                                  height: 250.h,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Error loading data. Please try again.',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: isDarkMode
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: () {
                                    log(
                                      'Retrying data fetch',
                                      name: 'ExploreScreen',
                                    );
                                    _fetchData();
                                    setState(() {});
                                  },
                                  child: Text(
                                    'Retry',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isDarkMode
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          final data = snapshot.data!;
                          final categories =
                              data['categories'] as List<CategoryModel>;
                          final tips = data['tips'] as List<TipModel>;
                          final canAccessPremium =
                              data['canAccessPremium'] as bool;

                          log(
                            'FutureBuilder data: categories=${categories.length}, '
                            'tips=${tips.length}',
                            name: 'ExploreScreen',
                          );

                          return ValueListenableBuilder<String>(
                            valueListenable: _searchQuery,
                            builder: (context, searchQuery, child) {
                              return FilteredContent(
                                key: ValueKey(
                                  '$_selectedCategoryId-$_selectedTipsType-$searchQuery',
                                ),
                                searchQuery: searchQuery,
                                selectedCategoryId: _selectedCategoryId,
                                selectedTipsType: _selectedTipsType,
                                categories: categories,
                                tips: tips,
                                onCategorySelected: (categoryId) {
                                  setState(() {
                                    _selectedCategoryId = categoryId;
                                  });
                                },
                                canAccessPremium: canAccessPremium,
                              );
                            },
                          );
                        },
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
}
