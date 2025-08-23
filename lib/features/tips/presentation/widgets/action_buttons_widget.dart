import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/tips_model.dart';
import '../../../../core/resources/colors.dart';

class ActionButtonsWidget extends StatelessWidget {
  final bool isFavorite;
  final bool isSlideshowEnabled;
  final bool isFullScreen;
  final bool showFullScreenIcon;
  final int countdown;
  final bool isDarkMode;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final VoidCallback onToggleSlideshow;
  final VoidCallback onToggleFullScreen;
  final TipModel tip;

  const ActionButtonsWidget({
    super.key,
    required this.isFavorite,
    required this.isSlideshowEnabled,
    required this.isFullScreen,
    required this.showFullScreenIcon,
    required this.countdown,
    required this.isDarkMode,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onToggleSlideshow,
    required this.onToggleFullScreen,
    required this.tip,
  });

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
    required String tooltip,
    Widget? child,
    Color? borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: borderColor ??
              (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                  .withOpacity(0.3),
          width: 1.5.w,
        ),
      ),
      child: IconButton(
        icon: child ?? Icon(icon, size: 28.sp, color: iconColor),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24.h,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: isFavorite
                ? Colors.redAccent
                : (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            onPressed: onToggleFavorite,
            tooltip: isFavorite ? 'Remove Favorite' : 'Add Favorite',
          ),
          SizedBox(width: 20.w),
          _buildActionButton(
            icon: Icons.share,
            iconColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            onPressed: onShare,
            tooltip: 'Share',
          ),
          SizedBox(width: 20.w),
          _buildActionButton(
            icon: isSlideshowEnabled ? Icons.pause : Icons.play_arrow,
            iconColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            onPressed: onToggleSlideshow,
            tooltip: isSlideshowEnabled ? 'Pause Slideshow' : 'Start Slideshow',
            child: isSlideshowEnabled
                ? Center(
              child: Text(
                '$countdown',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            )
                : Icon(
              Icons.play_arrow,
              size: 28.sp,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          if (showFullScreenIcon)
            Row(
              children: [
                SizedBox(width: 20.w),
                _buildActionButton(
                  icon: isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  iconColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  onPressed: onToggleFullScreen,
                  tooltip: isFullScreen ? 'Exit Full Screen' : 'Enter Full Screen',
                ),
              ],
            ),
        ],
      ),
    );
  }
}