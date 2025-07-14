import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/route_config/route_config.dart';
import 'package:wellness_app/screens/dashboard_screen.dart';

class UserPreferenceScreen extends StatefulWidget {
  const UserPreferenceScreen({super.key});

  @override
  State<UserPreferenceScreen> createState() => _UserPreferenceScreenState();
}

class _UserPreferenceScreenState extends State<UserPreferenceScreen> {
  final _formKey = GlobalKey<FormState>(); // For form validation if needed

  // List of preference topics
  final List<String> preferenceItems = [
    'Hard Times',
    'Working Out',
    'Productivity',
    'Self-Esteem',
    'Achieving Goals',
    'Inspiration',
    'Letting Go',
    'Love',
    'Relationships',
    'Faith & Spirituality',
    'Positive Thinking',
    'Stress & Anxiety',
  ];

  // Tracks whether each item is selected
  final List<bool> _selectedItems = List.filled(12, false);

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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.w, // Responsive padding
              right: 16.w,
              top: 20.h,
              bottom: 16.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button (top-left corner)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: theme.iconTheme.color, // Use theme icon color
                    size: 22.w, // Responsive icon size
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Navigate back to LoginScreen using named route
                    Navigator.pushReplacementNamed(
                      context,
                      RoutesName.loginScreen,
                    );
                  },
                ),
                SizedBox(height: 12.h), // Responsive spacing
                // Title text
                Text(
                  'Select all topics that motivate you',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 24.sp, // Responsive font size
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 20.h), // Responsive spacing
                // Form containing a grid of selectable topics
                Form(
                  key: _formKey,
                  child: GridView.builder(
                    shrinkWrap: true, // Prevent infinite space
                    physics: const NeverScrollableScrollPhysics(), // Disable inner scroll
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two cards per row
                      crossAxisSpacing: 10.w, // Responsive spacing
                      mainAxisSpacing: 10.h, // Responsive spacing
                      childAspectRatio: 2.5, // Width/height ratio
                    ),
                    itemCount: preferenceItems.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // Toggle selection state
                            _selectedItems[index] = !_selectedItems[index];
                          });
                        },
                        child: Card(
                          color: _selectedItems[index]
                              ? Colors.white
                              : theme.colorScheme.secondary, // Use theme secondary color for unselected
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r), // Responsive radius
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12.w), // Responsive padding
                            child: Center(
                              child: Text(
                                preferenceItems[index],
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _selectedItems[index]
                                      ? Colors.black
                                      : Colors.white, // Text color changes on selection
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp, // Responsive font size
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24.h), // Responsive spacing
                // Save preferences button
                ElevatedButton(
                  onPressed: () {
                    // Extract selected items
                    final selectedPreferences = preferenceItems
                        .asMap()
                        .entries
                        .where((entry) => _selectedItems[entry.key])
                        .map((entry) => entry.value)
                        .toList();

                    // Show selected preferences in snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 You’ve saved your preferences: $selectedPreferences'),
                      ),
                    );

                    // Navigate to DashboardScreen with DashboardViewModel
                    Navigator.pushReplacementNamed(
                      context,
                      RoutesName.dashboardScreen,
                      arguments: DashboardViewModel(), // Placeholder; replace with actual instance
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary, // Use theme secondary color
                    minimumSize: Size(double.infinity, 50.h), // Responsive height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r), // Responsive radius
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16.sp, // Responsive font size
                      color: Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(height: 20.h), // Responsive spacing
                // Back to Login (text button)
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Navigate to LoginScreen using named route
                      Navigator.pushReplacementNamed(
                        context,
                        RoutesName.loginScreen,
                      );
                    },
                    child: Text(
                      'Back to Login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp, // Responsive font size
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}