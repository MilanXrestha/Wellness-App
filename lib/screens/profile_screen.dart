import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/route_config/route_config.dart';
import 'package:wellness_app/service/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Instance of AuthService for user data and logout
  final AuthService _authService = AuthService();

  // Method to handle logout with confirmation dialog
  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 18.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await _authService.signOut();
                // Show green success SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Logged out successfully!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                // Navigate to LoginScreen
                Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
              } catch (e) {
                // Show red error SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text(
              'Logout',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for consistent status bar appearance
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Access ThemeData for consistent styling
    final theme = Theme.of(context);

    // Get current user data
    final user = _authService.getCurrentUser();
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'No email';
    final photoUrl = user?.photoURL ?? 'https://i.imgur.com/2iw4qeP.jpeg'; // Fallback image

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background color
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w, // Responsive horizontal padding
              vertical: 20.h, // Responsive vertical padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with back button and title
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: theme.iconTheme.color, // Use theme icon color
                        size: 22.w, // Responsive icon size
                      ),
                      onPressed: () {
                        // Navigate back to DashboardScreen
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: 8.w), // Responsive spacing
                    Text(
                      'Profile',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 24.sp, // Responsive font size
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25.h), // Responsive spacing
                // Profile card with dynamic avatar, name, and email
                Card(
                  color: theme.colorScheme.secondary, // Use theme secondary color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r), // Responsive radius
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30.w, // Responsive radius
                      backgroundImage: NetworkImage(photoUrl),
                    ),
                    title: Text(
                      displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 18.sp, // Responsive font size
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp, // Responsive font size
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h), // Responsive spacing
                // First section title
                Text(
                  'MAKE IT YOURS',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16.sp, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 10.h), // Responsive spacing
                // Content preferences menu item
                _buildMenuItem(
                  'ic_content_pref.svg',
                  'Content preferences',
                      () {
                    // TODO: Implement Content preferences functionality
                  },
                  26.w,
                  26.h,
                ),
                SizedBox(height: 10.h), // Responsive spacing
                // Second section title
                Text(
                  'ACCOUNT',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16.sp, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 10.h), // Responsive spacing
                // Menu items
                _buildMenuItem(
                  'ic_theme.svg',
                  'Theme',
                      () {
                    // TODO: Implement Theme functionality
                  },
                  20.w,
                  20.h,
                ),
                _buildMenuItem(
                  'ic_password.svg',
                  'Change Password',
                      () {
                    Navigator.pushNamed(context, RoutesName.changePasswordScreen);
                  },
                  30.w,
                  30.h,
                ),
                _buildMenuItem(
                  'ic_exit.svg',
                  'Logout',
                  _handleLogout,
                  20.w,
                  20.h,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds a menu item with an SVG icon, title, onTap action, and custom icon dimensions
  Widget _buildMenuItem(
      String svgFileName,
      String title,
      VoidCallback onTap,
      double iconWidth,
      double iconHeight,
      ) {
    return Card(
      color: Theme.of(context).colorScheme.secondary, // Use theme secondary color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r), // Responsive radius
      ),
      margin: EdgeInsets.only(bottom: 10.h), // Responsive margin
      child: ListTile(
        leading: SvgPicture.asset(
          'assets/images/svg/$svgFileName',
          width: iconWidth, // Responsive icon width
          height: iconHeight, // Responsive icon height
          colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 16.sp, // Responsive font size
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).iconTheme.color, // Use theme icon color
          size: 16.w, // Responsive icon size
        ),
        onTap: onTap,
      ),
    );
  }
}