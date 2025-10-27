import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/resources/colors.dart';

class SettingsDialogWidget extends StatefulWidget {
  final int initialCountdown;
  final bool initialShowFullScreenIcon;
  final bool initialShowSwipeIndicator;
  final bool initialSlideshowEnabled;
  final Function(int, bool, bool, bool) onSave;

  const SettingsDialogWidget({
    super.key,
    required this.initialCountdown,
    required this.initialShowFullScreenIcon,
    required this.initialShowSwipeIndicator,
    required this.initialSlideshowEnabled,
    required this.onSave,
  });

  @override
  State<SettingsDialogWidget> createState() => _SettingsDialogWidgetState();
}

class _SettingsDialogWidgetState extends State<SettingsDialogWidget> {
  late int _tempCountdown;
  late bool _tempShowFullScreenIcon;
  late bool _tempShowSwipeIndicator;
  late bool _tempSlideshowEnabled;

  @override
  void initState() {
    super.initState();
    _tempCountdown = widget.initialCountdown;
    _tempShowFullScreenIcon = widget.initialShowFullScreenIcon;
    _tempShowSwipeIndicator = widget.initialShowSwipeIndicator;
    _tempSlideshowEnabled = widget.initialSlideshowEnabled;
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSection(
    BuildContext context,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set slideshow transition speed (3-30 seconds)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 3,
                  max: 30,
                  divisions: 27,
                  label: '$value seconds',
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primary.withOpacity(0.3),
                  onChanged: (val) => onChanged(val.toInt()),
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                width: 80.w,
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$value s',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3s',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '30s',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.5),
              inactiveThumbColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.5),
              inactiveTrackColor: Theme.of(
                context,
              ).colorScheme.surface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      elevation: 8,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.sp),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 24.r,
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _buildSectionHeader(context, 'Slideshow Duration', Icons.timer),
              SizedBox(height: 16.h),
              _buildSliderSection(
                context,
                _tempCountdown,
                (value) => setState(() => _tempCountdown = value),
              ),
              SizedBox(height: 24.h),
              _buildSectionHeader(context, 'Display Options', Icons.settings),
              SizedBox(height: 16.h),
              _buildToggleOption(
                context,
                'Enable Slideshow',
                _tempSlideshowEnabled,
                (value) => setState(() => _tempSlideshowEnabled = value),
              ),
              SizedBox(height: 8.h),
              _buildToggleOption(
                context,
                'Show Full-Screen Icon',
                _tempShowFullScreenIcon,
                (value) => setState(() => _tempShowFullScreenIcon = value),
              ),
              SizedBox(height: 8.h),
              _buildToggleOption(
                context,
                'Show Swipe Indicator',
                _tempShowSwipeIndicator,
                (value) => setState(() => _tempShowSwipeIndicator = value),
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(
                        _tempCountdown,
                        _tempShowFullScreenIcon,
                        _tempShowSwipeIndicator,
                        _tempSlideshowEnabled,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
