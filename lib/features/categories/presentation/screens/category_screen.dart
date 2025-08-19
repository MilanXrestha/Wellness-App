import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'dart:developer';

class CategoryScreen extends StatefulWidget {
  final CategoryModel? selectedCategory;
  final ValueChanged<bool>? onSearchActiveChanged;

  const CategoryScreen({
    super.key,
    this.selectedCategory,
    this.onSearchActiveChanged,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<bool> _isSearchActive = ValueNotifier(false);
  final FocusNode _searchFocusNode = FocusNode();
  int _crossAxisCount = 2;
  static const String _gridLayoutKey = 'category_grid_layout';
  Future<List<CategoryModel>>? _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadGridLayout();
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _fetchCategories();
    if (widget.selectedCategory != null) {
      _navigateToCategoryDetail();
    }
  }

  Future<void> _loadGridLayout() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _crossAxisCount = prefs.getInt(_gridLayoutKey) ?? 2;
    });
  }

  Future<void> _saveGridLayout(int crossAxisCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gridLayoutKey, crossAxisCount);
  }

  void _fetchCategories() {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isEmpty) {
      log('No user ID found in _fetchCategories', name: 'CategoryScreen');
      return;
    }
    _categoriesFuture = DataRepository.instance.getCategories().catchError((
      e,
      stackTrace,
    ) {
      log(
        'Error fetching categories: $e',
        name: 'CategoryScreen',
        stackTrace: stackTrace,
      );
      throw e;
    });
  }

  void _toggleGridView() {
    setState(() {
      _crossAxisCount = _crossAxisCount % 3 + 1;
      _saveGridLayout(_crossAxisCount);
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
        name: 'CategoryScreen',
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
        log('Search deactivated via toggle', name: 'CategoryScreen');
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
          log(
            'Search activated via toggle, opening keyboard',
            name: 'CategoryScreen',
          );
        });
      }
    });
  }

  void _navigateToCategoryDetail() {
    if (widget.selectedCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(
          context,
          RoutesName.categoryDetailScreen,
          arguments: widget.selectedCategory,
        ).then((_) {
          if (mounted) setState(() {});
        });
      });
    }
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

  Widget _buildShimmerUI(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: _crossAxisCount == 1 ? 2.0 : 0.8,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return Shimmer.fromColors(
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
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        );
      }, childCount: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final userId = _authService.getCurrentUser()?.uid ?? '';

    if (userId.isEmpty) {
      log('No user ID found, redirecting to login', name: 'CategoryScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      });
      return const SizedBox.shrink();
    }

    if (widget.selectedCategory != null) {
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
          child: SafeArea(
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
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: isDarkMode
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors
                                                          .lightTextPrimary,
                                              ),
                                          decoration: InputDecoration(
                                            hintText: 'Search categories...',
                                            hintStyle: theme
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: isDarkMode
                                                      ? AppColors.darkTextHint
                                                      : AppColors.lightTextHint,
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
                                            'Categories',
                                            style: theme.textTheme.headlineSmall
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
                                      'assets/icons/svg/ic_grid.svg',
                                      width: 24.sp,
                                      height: 24.sp,
                                      color: isDarkMode
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextPrimary,
                                    ),
                                    onPressed: _toggleGridView,
                                    tooltip: 'Toggle Grid View',
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
                    vertical: 2.h,
                  ),
                  sliver: FutureBuilder<List<CategoryModel>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        log('FutureBuilder waiting', name: 'CategoryScreen');
                        return _buildShimmerUI(context);
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        log(
                          'FutureBuilder error: ${snapshot.error}',
                          name: 'CategoryScreen',
                        );
                        return SliverToBoxAdapter(
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
                                'Error loading categories. Please try again.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontSize: 16.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton(
                                onPressed: () {
                                  log(
                                    'Retrying category fetch',
                                    name: 'CategoryScreen',
                                  );
                                  _fetchCategories();
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
                          ),
                        );
                      }

                      final categories = snapshot.data!;
                      log(
                        'FutureBuilder data: categories=${categories.length}',
                        name: 'CategoryScreen',
                      );

                      return ValueListenableBuilder<String>(
                        valueListenable: _searchQuery,
                        builder: (context, searchQuery, child) {
                          final filteredCategories = categories
                              .where(
                                (category) => category.categoryName
                                    .toLowerCase()
                                    .contains(searchQuery),
                              )
                              .toList();

                          if (filteredCategories.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.darkSurface
                                      : AppColors.lightBackground,
                                  borderRadius: BorderRadius.circular(8.r),
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
                                      'No categories found. Try adjusting your search.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDarkMode
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextPrimary,
                                            fontSize: 14.sp,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _crossAxisCount,
                                  crossAxisSpacing: 12.w,
                                  mainAxisSpacing: 12.h,
                                  childAspectRatio: _crossAxisCount == 1
                                      ? 2.0
                                      : 0.8,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final category = filteredCategories[index];
                              final fontSize = _crossAxisCount == 1
                                  ? 18.sp
                                  : _crossAxisCount == 2
                                  ? 16.sp
                                  : 14.sp;

                              return Card(
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
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    log(
                                      'Tapped category: ${category.categoryName}',
                                      name: 'CategoryScreen',
                                    );
                                    Navigator.pushNamed(
                                      context,
                                      RoutesName.categoryDetailScreen,
                                      arguments: category,
                                    );
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: category.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Center(
                                          child: SizedBox(
                                            width: 20.w,
                                            height: 20.h,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.w,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              color: AppColors.primary
                                                  .withOpacity(0.2),
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 30.sp,
                                                color: isDarkMode
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : AppColors
                                                          .lightTextSecondary,
                                              ),
                                            ),
                                      ),
                                      Container(
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      Positioned(
                                        bottom: 10.h,
                                        left: 10.w,
                                        right: 10.w,
                                        child: Text(
                                          category.categoryName,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: AppColors.lightBackground,
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.8,
                                                ),
                                                blurRadius: 4.r,
                                                offset: Offset(1.w, 1.h),
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }, childCount: filteredCategories.length),
                          );
                        },
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
