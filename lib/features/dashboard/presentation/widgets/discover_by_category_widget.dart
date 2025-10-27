import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'dart:developer';

class CachedNetworkImageManager {
  static final CachedNetworkImageManager _instance = CachedNetworkImageManager._();

  static CachedNetworkImageManager get instance => _instance;

  final CacheManager cacheManager = CacheManager(
    Config(
      'categoryImagesCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'categoryImagesCache'),
      fileService: HttpFileService(),
    ),
  );

  CachedNetworkImageManager._();

  void preloadCategoryImages(List<CategoryModel> categories) {
    for (final category in categories) {
      if (category.imageUrl.isNotEmpty) {
        cacheManager.getSingleFile(category.imageUrl);
      }
    }
  }
}

/// A widget that displays a horizontal list of category cards.
class DiscoverByCategoryWidget extends StatefulWidget {
  /// List of valid categories to display.
  final List<CategoryModel> validCategories;

  /// Map of category IDs to their associated tips.
  final Map<String, List<dynamic>> categoryTips;

  /// The app's theme data for consistent styling.
  final ThemeData theme;

  /// Indicates whether dark mode is enabled.
  final bool isDarkMode;

  /// Callback to handle "View All" button to switch to Category tab.
  final VoidCallback onViewAllCategories;

  const DiscoverByCategoryWidget({
    super.key,
    required this.validCategories,
    required this.categoryTips,
    required this.theme,
    required this.isDarkMode,
    required this.onViewAllCategories,
  });

  @override
  State<DiscoverByCategoryWidget> createState() => _DiscoverByCategoryWidgetState();
}

class _DiscoverByCategoryWidgetState extends State<DiscoverByCategoryWidget> {

  @override
  void initState() {
    super.initState();
    // Preload category images when widget initializes
    if (widget.validCategories.isNotEmpty) {
      CachedNetworkImageManager.instance.preloadCategoryImages(widget.validCategories);
    }
  }

  /// Builds a section header with a title and view-all button.
  Widget _buildSectionHeader(
      BuildContext context, {
        required String title,
        required VoidCallback onViewAll,
        required String viewAllText,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: widget.theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Poppins',
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            viewAllText,
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              color: widget.isDarkMode ? AppColors.primary : Colors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a horizontal list of category cards with an empty state fallback.
  Widget _buildHorizontalList({
    required List<CategoryModel> items,
    required String emptyMessage,
    required BuildContext context,
  }) {
    return SizedBox(
      height: 130.h,
      child: items.isNotEmpty
          ? RepaintBoundary(
        key: ValueKey('category_list_${items.length}'),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: _buildCategoryCard(entry.value, context),
              ),
            )
                .toList(),
          ),
        ),
      )
          : Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          emptyMessage,
          style: widget.theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: widget.isDarkMode
                ? AppColors.darkTextSecondary
                : Colors.grey.shade600,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  /// Builds a single category card.
  Widget _buildCategoryCard(CategoryModel category, BuildContext context) {
    return SizedBox(
      width: 125.w,
      child: Card(
        key: ValueKey('category_card_${category.categoryId}'),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: widget.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            width: 1.w,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              if (widget.isDarkMode)
                BoxShadow(
                  color: AppColors.darkSurface.withOpacity(0.1),
                  blurRadius: 4.r,
                  spreadRadius: 0.5.r,
                  offset: Offset(0, 1.h),
                ),
              if (!widget.isDarkMode)
                BoxShadow(
                  color: Colors.black.withAlpha(38),
                  blurRadius: 4.r,
                  spreadRadius: 0.5.r,
                  offset: Offset(0, -1.h),
                ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                key: ValueKey('category_image_${category.categoryId}'),
                imageUrl: category.imageUrl,
                fit: BoxFit.cover,
                cacheManager: CachedNetworkImageManager.instance.cacheManager,
                // Remove or comment out these lines to preserve original quality
                // memCacheWidth: 250,
                // memCacheHeight: 260,
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 200),
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                placeholder: (_, __) => Container(
                  width: 120.w,
                  height: 130.h,
                  color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[400],
                ),
                errorWidget: (_, __, ___) => Container(
                  color: widget.isDarkMode
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.grey.shade100,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 30.sp,
                    color: widget.isDarkMode
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                    semanticLabel: 'Image not available',
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.black.withOpacity(0.6)
                      : Colors.black.withAlpha(102),
                ),
              ),
              Positioned(
                bottom: 6.h,
                left: 6.w,
                right: 6.w,
                child: Text(
                  category.categoryName,
                  style: widget.theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      log(
                        'Category card tapped: ${category.categoryName}',
                        name: 'DiscoverByCategoryWidget',
                      );
                      Navigator.pushNamed(
                        context,
                        RoutesName.categoryDetailScreen,
                        arguments: category,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.validCategories.isNotEmpty
        ? RepaintBoundary(
      child: Column(
        key: ValueKey('category_widget_${widget.validCategories.length}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          _buildSectionHeader(
            context,
            title: AppLocalizations.of(context)!.discoverByCategory,
            onViewAll: widget.onViewAllCategories,
            viewAllText: AppLocalizations.of(context)!.viewAll,
          ),
          SizedBox(height: 12.h),
          _buildHorizontalList(
            items: widget.validCategories,
            emptyMessage: AppLocalizations.of(
              context,
            )!.noCategoriesAvailable,
            context: context,
          ),
        ],
      ),
    )
        : const SizedBox.shrink();
  }
}