import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'dart:developer';

/// A widget that displays a horizontal list of category cards.
class DiscoverByCategoryWidget extends StatelessWidget {
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
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Poppins',
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            viewAllText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              color: isDarkMode ? AppColors.primary : Colors.black,
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
          ? SingleChildScrollView(
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
            )
          : Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Poppins',
                  color: isDarkMode
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
      width: 120.w,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            width: 1.w,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              if (isDarkMode)
                BoxShadow(
                  color: AppColors.darkSurface.withOpacity(0.1),
                  blurRadius: 4.r,
                  spreadRadius: 0.5.r,
                  offset: Offset(0, 1.h),
                ),
              if (!isDarkMode)
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
                imageUrl: category.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 120.w,
                  height: 130.h,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[400],
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDarkMode
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.grey.shade100,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 30.sp,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                    semanticLabel: 'Image not available',
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
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
                  style: theme.textTheme.bodyMedium?.copyWith(
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
    return validCategories.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              _buildSectionHeader(
                context,
                title: AppLocalizations.of(context)!.discoverByCategory,
                onViewAll: onViewAllCategories,
                viewAllText: AppLocalizations.of(context)!.viewAll,
              ),
              SizedBox(height: 12.h),
              _buildHorizontalList(
                items: validCategories,
                emptyMessage: AppLocalizations.of(
                  context,
                )!.noCategoriesAvailable,
                context: context,
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}
