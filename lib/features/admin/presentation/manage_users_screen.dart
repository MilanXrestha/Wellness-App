import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/features/profile/data/user_model.dart';
import 'package:wellness_app/features/preferences/data/models/user_preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, PreferenceModel> _preferenceCache = {};
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isPrefsLoaded = false;
  String _reloadKey = DateTime.now().toIso8601String();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadPreferences() async {
    final snapshot = await _firestore.collection('preferences').get();
    for (var doc in snapshot.docs) {
      _preferenceCache[doc.id] = PreferenceModel.fromFirestore(doc.data(), doc.id);
    }
    setState(() {
      _isPrefsLoaded = true;
    });
  }

  void _triggerReload() {
    setState(() {
      _reloadKey = DateTime.now().toIso8601String();
      _selectedUserIds.clear();
    });
  }

  Future<void> _changeUserRole(String userId, String userName, bool promote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promote ? AppStrings.promote : AppStrings.demote),
        content: Text('Are you sure you want to ${promote ? 'promote' : 'demote'} $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: promote ? AppColors.primary : AppColors.error,
            ),
            child: Text(promote ? AppStrings.promote : AppStrings.demote),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        if (promote) {
          await _authService.promoteToAdmin(userId);
        } else {
          await _authService.demoteToUser(userId);
        }
        if (!mounted) return;
        CustomBottomSheet.show(
          context: context,
          message: '$userName successfully ${promote ? 'promoted' : 'demoted'}.',
          isSuccess: true,
        );
      } catch (e) {
        if (!mounted) return;
        CustomBottomSheet.show(
          context: context,
          message: '${AppStrings.error} $e',
          isSuccess: false,
        );
      } finally {
        _triggerReload();
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildUserCard(UserModel user, List<String> preferences, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrent = currentUser?.uid == user.userId;
    final photoUrl = isCurrent ? currentUser?.photoURL : user.photoURL;
    final isSelected = _selectedUserIds.contains(user.userId);
    final createdAt = user.createdAt != null
        ? DateFormat('MMM d, yyyy').format(user.createdAt!)
        : 'Unknown';

    return FadeInUp(
      duration: Duration(milliseconds: 300 + index * 80),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUserIds.remove(user.userId);
            } else {
              _selectedUserIds.add(user.userId);
            }
          });
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          margin: EdgeInsets.only(bottom: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.darkSurface.withAlpha(230), AppColors.darkSurface.withAlpha(200)]
                  : [AppColors.lightSurface.withAlpha(230), AppColors.lightSurface.withAlpha(200)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.primary.withAlpha(77),
              width: isSelected ? 2.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: AppColors.primary.withAlpha(38),
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Text(
                      user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          user.userEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15.sp,
                            fontFamily: 'Roboto',
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5.h),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Joined: ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              TextSpan(
                                text: createdAt,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13.sp,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: Text(
                  'Preferences:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: preferences.map((p) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        p,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Role: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          TextSpan(
                            text: user.userRole.capitalize(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: user.userRole == 'admin' ? AppColors.primary : AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (user.userRole != 'admin')
                        ElevatedButton(
                          onPressed: () => _changeUserRole(user.userId, user.userName, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            AppStrings.promote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.lightBackground,
                            ),
                          ),
                        ),
                      if (user.userRole == 'admin') SizedBox(width: 8.w),
                      if (user.userRole == 'admin')
                        ElevatedButton(
                          onPressed: () => _changeUserRole(user.userId, user.userName, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            AppStrings.demote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.lightBackground,
                            ),
                          ),
                        ),
                      SizedBox(width: 8.w),
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: AnimationController(
                              duration: Duration(milliseconds: 400 + index * 80),
                              vsync: this,
                            )..forward(),
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.sendNotificationScreen,
                              arguments: [user.userId],
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withAlpha(153)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 6.r,
                                  offset: Offset(2.w, 2.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications,
                              size: 26.sp,
                              color: isDark ? AppColors.lightBackground : AppColors.lightBackground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isPrefsLoaded) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20.sp,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppStrings.manageUsersTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22.sp,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedUserIds.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            size: 22.sp,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.sendNotificationScreen,
                              arguments: _selectedUserIds.toList(),
                            );
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 22.sp,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        onPressed: _triggerReload,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchUsersHint,
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    key: ValueKey(_reloadKey),
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }

                      final users = userSnapshot.data!.docs
                          .map((doc) => UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                          .where((u) => u.userName.toLowerCase().contains(_searchQuery) || u.userEmail.toLowerCase().contains(_searchQuery))
                          .toList();

                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('userPreferences').snapshots(),
                        builder: (context, prefSnapshot) {
                          final Map<String, List<String>> userPrefsMap = {};
                          for (final user in users) {
                            final doc = prefSnapshot.data?.docs.firstWhereOrNull((d) => d.id == user.userId);
                            if (doc != null) {
                              final prefModel = UserPreferenceModel.fromFirestore(doc.data() as Map<String, dynamic>, user.userId);
                              userPrefsMap[user.userId] = prefModel.preferences
                                  .map((e) => _preferenceCache[e.preferenceId]?.preferenceName ?? '')
                                  .where((name) => name.isNotEmpty)
                                  .toList();
                            } else {
                              userPrefsMap[user.userId] = [];
                            }
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return _buildUserCard(user, userPrefsMap[user.userId] ?? [], index);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: AppColors.overlay,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}