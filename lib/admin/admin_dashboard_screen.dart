import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/route_config/route_config.dart';

// Main widget for the admin dashboard screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style to match dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
      ),
    );

    final theme = Theme.of(context); // Get current theme for styling

    // Reusable card widget for displaying stats
    Widget statCard({
      required String title,
      required String value,
      bool isTotalUsers = false,
      VoidCallback? onAdd,
    }) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF222222), // Dark card background
          borderRadius: BorderRadius.circular(12),
        ),
        child: isTotalUsers
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // Space icon and text
                children: [
                  SvgPicture.asset(
                    'assets/images/svg/ic_users.svg',
                    width: 60.w,
                    height: 60.w, // Larger icon
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ), // Ensure white icon
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // Align text to the right
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: Colors.white, fontSize: 15.sp),
                      ),
                      SizedBox(height: 10.h), // Gap between text and number
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Align text to the left
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 10.h), // Gap between text and number
                        Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onAdd != null)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: onAdd, // Trigger action on tap to navigate
                          child: Container(
                            width: 34.r,
                            height: 34.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF3A3A3A), // Add button background
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Increased space between icon and text
                        Text(
                          'Add New',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ), // Slightly larger text
                        ),
                      ],
                    ),
                ],
              ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          // Back button
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w), // Uniform padding for list
        children: [
          statCard(title: 'Total Users', value: '1488888', isTotalUsers: true),
          SizedBox(height: 16.h), // Spacing between cards
          statCard(
            title: 'Total Category',
            value: '100',
            onAdd: () => Navigator.pushReplacementNamed(
              context,
              RoutesName.addCategoryScreen,
            ),
          ),
          SizedBox(height: 16.h),
          statCard(
            title: 'Total Quotes',
            value: '200',
            onAdd: () => Navigator.pushReplacementNamed(
              context,
              RoutesName.addQuoteScreen,
            ),
          ),
          SizedBox(height: 16.h),
          statCard(
            title: 'Total Health Tips',
            value: '50',
            onAdd: () => Navigator.pushReplacementNamed(
              context,
              RoutesName.addHealthTipsScreen,
            ),
          ),
        ],
      ),
    );
  }
}
