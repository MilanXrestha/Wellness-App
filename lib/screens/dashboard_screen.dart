import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/service/auth_service.dart';

import '../core/route_config/route_config.dart';

// Placeholder for DashboardViewModel
class DashboardViewModel {}

class DashboardScreen extends StatefulWidget {
  final DashboardViewModel dashboardViewModel;

  const DashboardScreen({super.key, required this.dashboardViewModel});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Instance of AuthService to access user data
  final AuthService _authService = AuthService();
  String? _photoURL; // Store the user's profile photo URL

  @override
  void initState() {
    super.initState();
    // Load the user's profile photo URL
    final user = _authService.getCurrentUser();
    setState(() {
      _photoURL = user?.photoURL;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with title and avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 24.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    IconButton(
                      iconSize: 40.w,
                      padding: EdgeInsets.zero,
                      icon: CircleAvatar(
                        radius: 20.w,
                        backgroundImage: _photoURL != null && _photoURL!.isNotEmpty
                            ? NetworkImage(_photoURL!)
                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        onBackgroundImageError: (exception, stackTrace) {
                          // Fallback to default image if NetworkImage fails
                          setState(() {
                            _photoURL = null;
                          });
                        },
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, RoutesName.profileScreen);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/svg/ic_heart.svg',
                              width: 20.w,
                              height: 20.h,
                              colorFilter: const ColorFilter.mode(
                                Colors.white70,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'My Favorites',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14.sp,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/svg/ic_bell.svg',
                              width: 20.w,
                              height: 20.h,
                              colorFilter: const ColorFilter.mode(
                                Colors.white70,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Remind Me',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14.sp,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Today's Quotes title
                Text(
                  "Today's Quotes",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 10.h),

                // Quote Card
                Card(
                  color: theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"Your wellness is an investment, not an expense."',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 18.sp,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          '- Author Name',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14.sp,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Quotes section
                Text(
                  'Quotes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 10.h),
                _buildQuoteCard('Feeling blessed', 'assets/images/svg/ic_sun.svg'),
                _buildQuoteCard('Pride Month', 'assets/images/svg/ic_heart.svg'),
                _buildQuoteCard('Self-worth', 'assets/images/svg/ic_star.svg'),
                _buildQuoteCard('Love', 'assets/images/svg/ic_heart_filled.svg'),
                SizedBox(height: 20.h),

                // Health Tips section
                Text(
                  'Health Tips',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 10.h),
                _buildQuoteCard('Breathe to Reset', 'assets/images/svg/ic_sun.svg'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(String title, String svgIconPath) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      margin: EdgeInsets.only(bottom: 10.h),
      child: ListTile(
        leading: SvgPicture.asset(
          svgIconPath,
          width: 24.w,
          height: 24.h,
          colorFilter: const ColorFilter.mode(
            Colors.white70,
            BlendMode.srcIn,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16.sp,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.iconTheme.color,
          size: 16.w,
        ),
        onTap: () {
          Navigator.pushNamed(context, RoutesName.quotesDetailScreen);
        },
      ),
    );
  }
}