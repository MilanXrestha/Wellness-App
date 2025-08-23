import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final List<IconData> _icons = const [
    FontAwesomeIcons.house,
    FontAwesomeIcons.compass,
    FontAwesomeIcons.video,
    FontAwesomeIcons.layerGroup,
    FontAwesomeIcons.heart,
  ];

  final List<String> _labels = const [
    'Home',
    'Explore',
    'Shorts',
    'Category',
    'Favorite',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color neonGreen = const Color(0xFF3FF37F);
    final Color chipBackground = const Color(0xFF1E1E1E);
    final Color unselectedIconBg = const Color(0xFF262626);
    final Color selectedIconBg = neonGreen;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Row(
          children: List.generate(_icons.length, (index) {
            final bool isSelected = index == selectedIndex;

            if (isSelected) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: GestureDetector(
                  onTap: () => onItemTapped(index),
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: chipBackground,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedIconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _icons[index],
                            size: 18.sp,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            _labels[index],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Expanded(
                child: GestureDetector(
                  onTap: () => onItemTapped(index),
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: unselectedIconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icons[index],
                        size: 20.sp,
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }
          }),
        ),
      ),
    );
  }
}