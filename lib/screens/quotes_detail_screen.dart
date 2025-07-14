import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuotesDetailScreen extends StatefulWidget {
  const QuotesDetailScreen({super.key});

  @override
  State<QuotesDetailScreen> createState() => _QuotesDetailScreenState();
}

class _QuotesDetailScreenState extends State<QuotesDetailScreen> {
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background color
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0), // Responsive padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
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
                  // Screen title
                  Text(
                    'Motivation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 20.sp, // Responsive font size
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  // Page indicator badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w, // Responsive padding
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary, // Use theme secondary color
                      borderRadius: BorderRadius.circular(8.r), // Responsive radius
                    ),
                    child: Text(
                      '1/15',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp, // Responsive font size
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Volume icon with spacing
            SizedBox(height: 20.h), // Responsive spacing
            Padding(
              padding: EdgeInsets.only(right: 16.w), // Responsive padding
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondary, // Use theme secondary color
                  ),
                  padding: EdgeInsets.all(16.w), // Responsive padding
                  child: SvgPicture.asset(
                    'assets/images/svg/ic_volume_up.svg',
                    width: 36.w, // Responsive icon size
                    height: 36.h,
                    colorFilter: const ColorFilter.mode(
                      Colors.white70,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            // Quote section
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w), // Responsive padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Quote text with styled quote marks
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 22.sp, // Responsive font size
                            fontFamily: 'Poppins',
                          ),
                          children: [
                            // Opening quote mark with vertical offset
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Transform.translate(
                                offset: Offset(0, 3.h), // Responsive offset
                                child: Text(
                                  '“',
                                  style: TextStyle(
                                    fontSize: 42.sp, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'PlayfairDisplay',
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            // Small space after quote mark
                            WidgetSpan(child: SizedBox(width: 4.w)), // Responsive spacing
                            // Main quote content
                            TextSpan(
                              text:
                              'The only way to do great work is to love what you do.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 16.sp, // Responsive font size
                                fontFamily: 'Poppins',
                              ),
                            ),
                            // Small space before closing quote
                            WidgetSpan(child: SizedBox(width: 4.w)), // Responsive spacing
                            // Closing quote mark with vertical offset
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Transform.translate(
                                offset: Offset(0, 3.h), // Responsive offset
                                child: Text(
                                  '”',
                                  style: TextStyle(
                                    fontSize: 42.sp, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'PlayfairDisplay',
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h), // Responsive spacing
                      // Author name
                      Text(
                        '- Steve Jobs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 20.sp, // Responsive font size
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom section with swipe hint and icons
            Padding(
              padding: EdgeInsets.all(16.w), // Responsive padding
              child: Column(
                children: [
                  // Swipe up icon
                  SvgPicture.asset(
                    'assets/images/svg/ic_swipe_up.svg',
                    width: 40.w, // Responsive icon size
                    height: 40.h,
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: 8.h), // Responsive spacing
                  // Swipe up label
                  Text(
                    'Swipe up',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 21.sp, // Responsive font size
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 50.h), // Responsive spacing
                  // Action icons (heart and collection)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Heart icon
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement heart icon functionality (e.g., favorite quote)
                        },
                        child: SvgPicture.asset(
                          'assets/images/svg/ic_heart.svg',
                          width: 36.w, // Responsive icon size
                          height: 36.h,
                          colorFilter: const ColorFilter.mode(
                            Colors.white70,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w), // Responsive spacing
                      // Collection icon
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement collection icon functionality (e.g., add to collection)
                        },
                        child: SvgPicture.asset(
                          'assets/images/svg/ic_collection.svg',
                          width: 50.w, // Responsive icon size
                          height: 50.h,
                          colorFilter: const ColorFilter.mode(
                            Colors.white70,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}