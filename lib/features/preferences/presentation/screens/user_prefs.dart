import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/preferences/data/services/preference_service.dart';
import 'package:flip_card/flip_card.dart';
import '../../data/models/preference_model.dart';
import '../../../profile/data/user_model.dart';
import '../../data/models/user_preference_model.dart';
import '../../../main/presentation/screens/main_screen.dart';

/// Widget for displaying the user preference selection screen
class UserPreferenceScreen extends StatefulWidget {
  final bool fromProfile;

  const UserPreferenceScreen({super.key, this.fromProfile = false});

  @override
  State<UserPreferenceScreen> createState() => _UserPreferenceScreenState();
}

class _UserPreferenceScreenState extends State<UserPreferenceScreen> {
  final PreferenceService _preferenceService = PreferenceService();
  final AuthService _authService = AuthService();
  late ValueNotifier<List<bool>> _selectedItemsNotifier;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<GlobalKey<FlipCardState>> _flipCardKeys = [];
  List<PreferenceModel> _preferences = [];

  @override
  void initState() {
    super.initState();
    _selectedItemsNotifier = ValueNotifier<List<bool>>([]);
  }

  @override
  void dispose() {
    _selectedItemsNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Updates the last login timestamp in SharedPreferences
  Future<void> _updateLastLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_login_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Saves selected preferences to Firestore and updates preferenceCompleted
  Future<void> _savePreferences(List<PreferenceModel> selectedPreferences) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No authenticated user found');

      if (selectedPreferences.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select at least one preference to continue.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final preferences = selectedPreferences
          .map(
            (pref) => UserPreferenceEntry(
          preferenceId: pref.preferenceId,
          selectedAt: DateTime.now(),
        ),
      )
          .toList();

      await _preferenceService.saveUserPreferences(user.uid, preferences);

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final existingCreatedAt = (userDoc.data()?['createdAt'] as Timestamp?)?.toDate();
      final existingPhotoUrl = userDoc.data()?['photoURL'] as String? ?? user.photoURL;

      final userModel = UserModel(
        userId: user.uid,
        userEmail: user.email ?? '',
        userName: user.displayName ?? 'User',
        userRole: 'user',
        photoURL: existingPhotoUrl,
        preferenceCompleted: true,
        createdAt: existingCreatedAt ?? DateTime.now(),
      );
      await _authService.saveUserData(userModel);
      await _updateLastLoginTimestamp();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preferences saved successfully!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        if (widget.fromProfile) {
          Navigator.pop(context); // Return to ProfileScreen
        } else {
          // Smooth transition to mainScreen with slide and fade
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var slideAnimation = animation.drive(slideTween);

                var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
                var fadeAnimation = animation.drive(fadeTween);

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Renders icons based on type (SVG or image) from network or assets
  Widget _buildIcon(PreferenceModel pref, bool selected, ThemeData theme, bool isDark) {
    final color = selected
        ? (isDark ? AppColors.primary : AppColors.lightTextPrimary) // Black for light mode selected
        : (isDark ? theme.colorScheme.onSurfaceVariant : AppColors.lightTextSecondary); // Gray for unselected

    if (pref.isNetworkIcon) {
      if (pref.isSvg) {
        return SvgPicture.network(
          pref.preferenceIcon,
          width: 28.sp,
          height: 28.sp,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          placeholderBuilder: (context) => CircularProgressIndicator(strokeWidth: 2.w),
          fit: BoxFit.cover,
        );
      } else {
        return CachedNetworkImage(
          imageUrl: pref.preferenceIcon,
          width: 28.sp,
          height: 28.sp,
          placeholder: (context, url) => CircularProgressIndicator(strokeWidth: 2.w),
          errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 28.sp, color: color),
          color: color,
        );
      }
    } else {
      return Image.asset(
        'assets/icons/${pref.preferenceIcon}.png',
        width: 28.sp,
        height: 28.sp,
        color: color,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 28.sp, color: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return Stack(
      children: [
        Scaffold(
          appBar: widget.fromProfile
              ? AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20.sp,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, // Black for light
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Content Preferences',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary, // Black for light
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            backgroundColor: Colors.transparent, // No background
            elevation: 0,
          )



              : null,
          body: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? null // Keep dark mode as is
                  : AppColors.lightBackground, // Pure white for light mode (Apple clean vibe)
              gradient: isDark
                  ? LinearGradient( // Keep dark mode gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkSurface.withAlpha(230),
                  theme.scaffoldBackgroundColor,
                ],
              )
                  : null, // No gradient for light mode
            ),
            child: SafeArea(
              child: StreamBuilder<List<PreferenceModel>>(
                stream: _preferenceService.streamPreferences(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString().replaceFirst('Exception: ', ''),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Poppins',
                          color: theme.colorScheme.error,
                        ),
                      ),
                    );
                  }

                  _preferences = snapshot.data ?? [];
                  // Initialize _selectedItemsNotifier and _flipCardKeys
                  if (_selectedItemsNotifier.value.length != _preferences.length ||
                      _flipCardKeys.length != _preferences.length) {
                    _selectedItemsNotifier.value = List<bool>.filled(
                      _preferences.length,
                      false,
                    );
                    _flipCardKeys = List.generate(
                      _preferences.length,
                          (_) => GlobalKey<FlipCardState>(),
                    );
                  }

                  return StreamBuilder<UserPreferenceModel?>(
                    stream: widget.fromProfile
                        ? _preferenceService.streamUserPreferences(_authService.getCurrentUser()?.uid ?? '')
                        : null,
                    builder: (context, userSnapshot) {
                      if (widget.fromProfile &&
                          userSnapshot.connectionState == ConnectionState.active &&
                          userSnapshot.hasData) {
                        final userPreferences = userSnapshot.data?.preferences ?? [];
                        final selectedItems = List<bool>.filled(_preferences.length, false);
                        for (int i = 0; i < _preferences.length; i++) {
                          if (userPreferences.any((entry) => entry.preferenceId == _preferences[i].preferenceId)) {
                            selectedItems[i] = true;
                          }
                        }
                        _selectedItemsNotifier.value = selectedItems;
                      }

                      return ValueListenableBuilder<List<bool>>(
                        valueListenable: _selectedItemsNotifier,
                        builder: (context, selectedItems, _) {
                          final selectedCount = selectedItems.where((item) => item).length;

                          return Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            thickness: 6.w,
                            radius: Radius.circular(3.r),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 24.h,
                                    ),
                                    child: FadeInDown(
                                      duration: const Duration(milliseconds: 500),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(16.w),
                                                decoration: BoxDecoration(
                                                  gradient: isDark
                                                      ? LinearGradient( // Keep dark mode
                                                    colors: [
                                                      AppColors.primary.withAlpha(51),
                                                      AppColors.primary.withAlpha(26),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                      : LinearGradient( // Subtle white-gray for light (consistent with Profile)
                                                    colors: [
                                                      Colors.white,
                                                      Colors.grey.shade100,
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  border: Border.all(
                                                    color: isDark ? Colors.transparent : Colors.grey.shade300, // Gray border for light
                                                    width: 1.w,
                                                  ),
                                                  boxShadow: isDark
                                                      ? [] // Keep dark as is
                                                      : [
                                                    BoxShadow(
                                                      color: AppColors.lightTextPrimary.withOpacity(0.2), // Subtle shadow
                                                      blurRadius: 8.r,
                                                      offset: Offset(0, 2.h),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      widget.fromProfile
                                                          ? 'Update Your Interests'
                                                          : 'Craft Your Journey',
                                                      style: theme.textTheme.headlineMedium?.copyWith(
                                                        fontFamily: 'Poppins',
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? AppColors.primary : AppColors.lightTextPrimary, // Black for light
                                                        fontSize: 28.sp,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    Text(
                                                      widget.fromProfile
                                                          ? 'Modify your preferences to tailor your experience.'
                                                          : 'Choose topics that spark inspiration.',
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        fontFamily: 'Poppins',
                                                        color: isDark
                                                            ? theme.colorScheme.onSurfaceVariant
                                                            : AppColors.lightTextSecondary, // Gray for light
                                                        fontSize: 16.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (selectedCount > 0)
                                                Positioned(
                                                  top: 8.h,
                                                  right: 8.w,
                                                  child: CircleAvatar(
                                                    radius: 12.r,
                                                    backgroundColor: isDark
                                                        ? AppColors.primary // Keep dark
                                                        : AppColors.lightTextPrimary, // Black badge for light (Nike bold)
                                                    child: Text(
                                                      '$selectedCount',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.white,
                                                        fontSize: 12.sp,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 8.h),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                    child: GridView.builder(
                                      itemCount: _preferences.length,
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12.w,
                                        mainAxisSpacing: 12.h,
                                        childAspectRatio: 1.5,
                                      ),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final pref = _preferences[index];
                                        final selected = selectedItems[index];

                                        return FadeInUp(
                                          duration: Duration(milliseconds: 300 + (index * 80)),
                                          child: FlipCard(
                                            key: _flipCardKeys[index],
                                            flipOnTouch: true,
                                            direction: FlipDirection.HORIZONTAL,
                                            front: GestureDetector(
                                              onTap: () {
                                                final updated = List<bool>.from(selectedItems);
                                                updated[index] = !selected;
                                                _selectedItemsNotifier.value = updated;
                                                if (!selected) {
                                                  _flipCardKeys[index].currentState?.toggleCard();
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: isDark
                                                      ? null // Keep dark as is
                                                      : LinearGradient( // Subtle white-gray gradient for light (like Profile cards)
                                                    colors: [
                                                      Colors.white,
                                                      Colors.grey.shade100,
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  color: isDark
                                                      ? (selected
                                                      ? AppColors.primary.withAlpha(38)
                                                      : AppColors.darkSurface.withAlpha(230))
                                                      : null, // No color override for light (use gradient)
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? (selected ? AppColors.primary : theme.dividerColor.withAlpha(77))
                                                        : (selected ? AppColors.lightTextPrimary : Colors.grey.shade300), // Black border for selected light, gray for unselected
                                                    width: 1.w, // Thinner for minimalism
                                                  ),
                                                  boxShadow: isDark
                                                      ? (selected
                                                      ? [
                                                    BoxShadow(
                                                      color: AppColors.primary.withAlpha(77),
                                                      blurRadius: 12.r,
                                                      offset: Offset(0, 4.h),
                                                    )
                                                  ]
                                                      : [])
                                                      : [
                                                    BoxShadow(
                                                      color: selected
                                                          ? AppColors.lightTextPrimary.withOpacity(0.2) // Subtle black shadow for selected
                                                          : Colors.grey.shade200, // Very light gray shadow for unselected
                                                      blurRadius: 8.r,
                                                      offset: Offset(0, 2.h),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    _buildIcon(pref, selected, theme, isDark),
                                                    SizedBox(height: 8.h),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                                                      child: Text(
                                                        pref.preferenceName,
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          fontFamily: 'Poppins',
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark
                                                              ? (selected ? Colors.white : theme.colorScheme.onSurface)
                                                              : (selected ? AppColors.lightTextPrimary : AppColors.lightTextSecondary), // Black for selected light, gray for unselected
                                                          fontSize: 14.sp,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            back: GestureDetector(
                                              onTap: () {
                                                final updated = List<bool>.from(selectedItems);
                                                updated[index] = !selected;
                                                _selectedItemsNotifier.value = updated;
                                                if (selected) {
                                                  _flipCardKeys[index].currentState?.toggleCard();
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: isDark
                                                      ? null // Keep dark as is
                                                      : LinearGradient( // Subtle white-gray for back side
                                                    colors: [
                                                      Colors.white,
                                                      Colors.grey.shade100,
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  color: isDark
                                                      ? (selected
                                                      ? AppColors.primary.withAlpha(51)
                                                      : AppColors.darkSurface.withAlpha(242))
                                                      : null,
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? (selected ? AppColors.primary : theme.dividerColor.withAlpha(77))
                                                        : (selected ? AppColors.lightTextPrimary : Colors.grey.shade300),
                                                    width: 1.w,
                                                  ),
                                                  boxShadow: isDark
                                                      ? (selected
                                                      ? [
                                                    BoxShadow(
                                                      color: AppColors.primary.withAlpha(77),
                                                      blurRadius: 12.r,
                                                      offset: Offset(0, 4.h),
                                                    )
                                                  ]
                                                      : [])
                                                      : [
                                                    BoxShadow(
                                                      color: selected
                                                          ? AppColors.lightTextPrimary.withOpacity(0.2)
                                                          : Colors.grey.shade200,
                                                      blurRadius: 8.r,
                                                      offset: Offset(0, 2.h),
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(12.w),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      _buildIcon(pref, selected, theme, isDark),
                                                      SizedBox(height: 8.h),
                                                      Expanded(
                                                        child: Text(
                                                          pref.preferenceDescription,
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            fontFamily: 'Poppins',
                                                            color: isDark
                                                                ? (selected ? Colors.white : theme.colorScheme.onSurfaceVariant)
                                                                : (selected ? AppColors.lightTextPrimary : AppColors.lightTextSecondary), // Black/gray for light
                                                            fontSize: 12.sp,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 25.w,
                                      vertical: 25.h,
                                    ),
                                    child: ZoomIn(
                                      duration: const Duration(milliseconds: 500),
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                          final selectedPreferences = _preferences
                                              .asMap()
                                              .entries
                                              .where(
                                                (entry) => selectedItems[entry.key],
                                          )
                                              .map((entry) => entry.value)
                                              .toList();

                                          _savePreferences(selectedPreferences);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark
                                              ? null // Keep dark as is
                                              : AppColors.lightTextPrimary, // Solid black button for light (Nike bold contrast)
                                          foregroundColor: Colors.white, // White text for high contrast
                                          shadowColor: isDark ? null : Colors.grey.shade300, // Subtle gray shadow for light
                                          elevation: isDark ? null : 2, // Light elevation for depth
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(double.infinity, 40.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16.r),
                                          ),
                                        ),
                                        child: Ink(
                                          decoration: isDark
                                              ? BoxDecoration( // Keep dark gradient
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primary.withAlpha(178),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16.r),
                                          )
                                              : BoxDecoration( // No gradient for light (solid black)
                                            color: AppColors.lightTextPrimary,
                                            borderRadius: BorderRadius.circular(16.r),
                                          ),
                                          child: Container(
                                            height: 50.h,
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Save Preferences',
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white, // White text on black button
                                                fontSize: 20.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}