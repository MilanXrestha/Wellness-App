import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import '../../../core/config/routes/route_name.dart';

class ManagePreferencesScreen extends StatefulWidget {
  const ManagePreferencesScreen({super.key});

  @override
  State<ManagePreferencesScreen> createState() =>
      _ManagePreferencesScreenState();
}

class _ManagePreferencesScreenState extends State<ManagePreferencesScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String _reloadKey = DateTime.now().toIso8601String();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerReload() {
    setState(() {
      _reloadKey = DateTime.now().toIso8601String();
    });
  }

  void _showError(String message) {
    if (mounted) {
      CustomBottomSheet.show(
        context: context,
        message: message,
        isSuccess: false,
      );
    }
  }

  void _deletePreference(String id, String name) async {
    final confirm = await CustomAlertDialog.show(
      context: context,
      message: 'Are you sure you want to delete "$name"?',
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('preferences').doc(id).delete();
        _triggerReload();
        if (!mounted) return;
        CustomBottomSheet.show(
          context: context,
          message: 'Preference "$name" deleted successfully!',
          isSuccess: true,
        );
      } catch (e) {
        _showError('${AppStrings.error} $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editPreference(PreferenceModel preference) {
    Navigator.pushNamed(
      context,
      RoutesName.addPreferenceScreen,
      arguments: preference,
    ).then((_) => _triggerReload());
  }

  Widget _buildPreferenceCard(PreferenceModel preference, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return FadeInUp(
      duration: Duration(milliseconds: 300 + index * 80),
      child: Container(
        padding: EdgeInsets.all(12.w),
        margin: EdgeInsets.only(bottom: 14.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
              AppColors.darkSurface.withAlpha(230),
              AppColors.darkSurface.withAlpha(200),
            ]
                : [
              AppColors.lightSurface.withAlpha(230),
              AppColors.lightSurface.withAlpha(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primary.withAlpha(77),
            width: 1.w,
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
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(51),
                        AppColors.primary.withAlpha(26),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 6.r,
                        offset: Offset(2.w, 2.h),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: preference.isSvg
                        ? SvgPicture.network(
                      preference.preferenceIcon,
                      width: 45.w,
                      height: 45.w,
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                      placeholderBuilder: (_) => Icon(
                        Icons.broken_image,
                        color: AppColors.error,
                        size: 45.sp,
                      ),
                    )
                        : preference.isNetworkIcon
                        ? Image.network(
                      preference.preferenceIcon,
                      width: 45.w,
                      height: 45.w,
                      fit: BoxFit.cover,
                      color: iconColor,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image,
                        color: AppColors.error,
                        size: 45.sp,
                      ),
                    )
                        : Image.asset(
                      'assets/icons/${preference.preferenceIcon}.png',
                      width: 45.w,
                      height: 45.w,
                      fit: BoxFit.cover,
                      color: iconColor,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image,
                        color: AppColors.error,
                        size: 45.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preference.preferenceName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        preference.preferenceDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.sp,
                          fontFamily: 'Roboto',
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                    onTap: () => _editPreference(preference),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withAlpha(153),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 6.r,
                            offset: Offset(2.w, 2.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 26.sp,
                            color: AppColors.lightBackground,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            AppStrings.edit,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.lightBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
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
                    onTap: () => _deletePreference(
                      preference.preferenceId,
                      preference.preferenceName,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.error, AppColors.error],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 6.r,
                            offset: Offset(2.w, 2.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever_rounded,
                            size: 26.sp,
                            color: AppColors.lightBackground,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            AppStrings.delete,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.lightBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20.sp,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.primary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        AppStrings.managePreferencesTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22.sp,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 22.sp,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.primary,
                        ),
                        onPressed: _triggerReload,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchPreferencesHint,
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
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
                    stream: _firestore.collection('preferences').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      final preferences = snapshot.data!.docs
                          .map(
                            (doc) => PreferenceModel.fromFirestore(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                          .where(
                            (preference) =>
                        preference.preferenceName
                            .toLowerCase()
                            .contains(_searchQuery) ||
                            preference.preferenceDescription
                                .toLowerCase()
                                .contains(_searchQuery),
                      )
                          .toList();

                      return preferences.isEmpty
                          ? Center(
                        child: Text(
                          AppStrings.noPreferencesFound,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                            fontSize: 16.sp,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      )
                          : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        itemCount: preferences.length,
                        itemBuilder: (context, index) {
                          return _buildPreferenceCard(
                            preferences[index],
                            index,
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
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () => Navigator.pushNamed(
          context,
          RoutesName.addPreferenceScreen,
        ).then((_) => _triggerReload()),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withAlpha(153)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Icon(Icons.add, color: AppColors.lightBackground, size: 28.sp),
        ),
      ),
    );
  }
}