import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import '../../../core/config/routes/route_name.dart';
import '../../tips/data/models/tips_model.dart';

class ManageTipsScreen extends StatefulWidget {
  const ManageTipsScreen({super.key});

  @override
  State<ManageTipsScreen> createState() => _ManageTipsScreenState();
}

class _ManageTipsScreenState extends State<ManageTipsScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, CategoryModel> _categoryCache = {};
  final Map<String, PreferenceModel> _preferenceCache = {};
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isDataLoaded = false;
  String _reloadKey = DateTime.now().toIso8601String();

  @override
  void initState() {
    super.initState();
    _loadData();
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

  // Loads categories and preferences into cache
  Future<void> _loadData() async {
    try {
      final categorySnapshot = await _firestore.collection('categories').get();
      final preferenceSnapshot = await _firestore.collection('preferences').get();
      for (var doc in categorySnapshot.docs) {
        _categoryCache[doc.id] = CategoryModel.fromFirestore(doc.data(), doc.id);
      }
      for (var doc in preferenceSnapshot.docs) {
        _preferenceCache[doc.id] = PreferenceModel.fromFirestore(doc.data(), doc.id);
      }
      setState(() => _isDataLoaded = true);
    } catch (e) {
      _showError('${AppStrings.error} $e');
    }
  }

  // Triggers a reload of the tips list
  void _triggerReload() {
    setState(() {
      _reloadKey = DateTime.now().toIso8601String();
    });
  }

  // Shows error message in CustomBottomSheet
  void _showError(String message) {
    if (mounted) {
      CustomBottomSheet.show(context: context, message: message, isSuccess: false);
    }
  }

  // Deletes a tip with confirmation
  void _deleteTip(String id, String title) async {
    final confirm = await CustomAlertDialog.show(
      context: context,
      message: 'Are you sure you want to delete "$title"?',
      confirmText: AppStrings.delete,
      cancelText: AppStrings.cancel,
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('tips').doc(id).delete();
        _triggerReload();
        if (!mounted) return;
        CustomBottomSheet.show(
          context: context,
          message: 'Tip "$title" deleted successfully!',
          isSuccess: true,
        );
      } catch (e) {
        _showError('${AppStrings.error} $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Navigates to edit tip screen
  void _editTip(TipModel tip) {
    Navigator.pushNamed(
      context,
      RoutesName.addTipsScreen,
      arguments: tip,
    ).then((_) => _triggerReload());
  }

  // Builds preference chips
  List<Widget> _buildPreferenceChips(List<String> preferenceIds) {
    return preferenceIds.map((id) {
      final pref = _preferenceCache[id] ?? PreferenceModel(
        preferenceId: id,
        preferenceName: 'Unknown',
        preferenceDescription: '',
        preferenceIcon: '',
      );
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        margin: EdgeInsets.only(right: 6.w, bottom: 6.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary.withAlpha(77)),
        ),
        child: Text(
          pref.preferenceName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.sp,
            fontFamily: 'Poppins',
            color: AppColors.primary,
          ),
        ),
      );
    }).toList();
  }

  // Builds category chip
  Widget _buildCategoryChip(String categoryId) {
    final category = _categoryCache[categoryId] ?? CategoryModel(
      categoryId: categoryId,
      categoryName: 'Unknown',
      categoryDescription: '',
      imageUrl: '',
      preferenceIds: [],
      createdAt: DateTime.now(),
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withAlpha(77)),
      ),
      child: Text(
        category.categoryName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12.sp,
          fontFamily: 'Poppins',
          color: AppColors.primary,
        ),
      ),
    );
  }

  // Maps tipsType to an icon
  IconData _getTipTypeIcon(String tipsType) {
    switch (tipsType.toLowerCase()) {
      case 'quote':
        return Icons.format_quote;
      case 'tip':
        return Icons.lightbulb;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'exercise':
        return Icons.fitness_center;
      case 'article':
        return Icons.article;
      case 'image':
        return Icons.image;
      case 'reminder':
        return Icons.alarm;
      case 'challenge':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }

  // Builds a tip card with details and actions
  Widget _buildTipCard(TipModel tip, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeInUp(
      duration: Duration(milliseconds: 300 + index * 80),
      child: Container(
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
              AppColors.darkSurface.withOpacity(0.9),
              AppColors.darkSurface.withOpacity(0.7),
            ]
                : [
              AppColors.lightSurface.withOpacity(0.95),
              AppColors.lightSurface.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.2),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
              spreadRadius: 2.r,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon for tipsType
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.1),
                    blurRadius: 6.r,
                    offset: Offset(2.w, 2.h),
                  ),
                ],
              ),
              child: Icon(
                _getTipTypeIcon(tip.tipsType),
                color: AppColors.primary,
                size: 40.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.tipsTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    tip.tipsDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontFamily: 'Roboto',
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  if (tip.tipsAuthor.isNotEmpty) ...[
                    Text(
                      'Author: ${tip.tipsAuthor}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13.sp,
                        fontFamily: 'Poppins',
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                  ],
                  Text(
                    'Type: ${tip.tipsType.capitalize()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13.sp,
                      fontFamily: 'Poppins',
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        'Category:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      _buildCategoryChip(tip.categoryId),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (tip.preferenceIds.isNotEmpty) ...[
                    Text(
                      'Preferences:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: _buildPreferenceChips(tip.preferenceIds),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ZoomIn(
                        duration: Duration(milliseconds: 400 + index * 80),
                        child: GestureDetector(
                          onTap: () => _editTip(tip),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withOpacity(0.3),
                                  blurRadius: 6.r,
                                  offset: Offset(2.w, 2.h),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 24.sp,
                                  color: AppColors.lightBackground,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  AppStrings.edit,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lightBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      ZoomIn(
                        duration: Duration(milliseconds: 400 + index * 80),
                        child: GestureDetector(
                          onTap: () => _deleteTip(tip.tipsId, tip.tipsTitle),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.error,
                                  AppColors.error.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withOpacity(0.3),
                                  blurRadius: 6.r,
                                  offset: Offset(2.w, 2.h),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_forever_rounded,
                                  size: 24.sp,
                                  color: AppColors.lightBackground,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  AppStrings.delete,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isDataLoaded) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ZoomIn(
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            size: 22.sp,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          AppStrings.manageTipsTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24.sp,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ZoomIn(
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          icon: Icon(
                            Icons.refresh,
                            size: 24.sp,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
                          ),
                          onPressed: _triggerReload,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchTipsHint,
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        size: 24.sp,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          size: 24.sp,
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface.withOpacity(0.9)
                          : AppColors.lightSurface.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    ),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    key: ValueKey(_reloadKey),
                    stream: _firestore.collection('tips').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      final tips = snapshot.data!.docs
                          .map((doc) => TipModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                          .where(
                            (tip) =>
                        tip.tipsTitle.toLowerCase().contains(_searchQuery) ||
                            tip.tipsDescription.toLowerCase().contains(_searchQuery),
                      )
                          .toList();

                      return tips.isEmpty
                          ? Center(
                        child: Text(
                          AppStrings.noTipsFound,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                          : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        itemCount: tips.length,
                        itemBuilder: (context, index) {
                          return _buildTipCard(tips[index], index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: AppColors.overlay.withOpacity(0.5),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
          ],
        ),
      ),
      floatingActionButton: ZoomIn(
        duration: const Duration(milliseconds: 400),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => Navigator.pushNamed(context, RoutesName.addTipsScreen).then((_) => _triggerReload()),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: 2.r,
                ),
              ],
            ),
            child: Icon(Icons.add, color: AppColors.lightBackground, size: 30.sp),
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}