import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

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
  Future<void> _deleteTip(String id, String title) async {
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
        if (!mounted) return;
        CustomBottomSheet.show(
          context: context,
          message: 'Tip "$title" deleted successfully!',
          isSuccess: true,
        );
      } catch (e) {
        _showError('${AppStrings.error} $e');
      } finally {
        _triggerReload();
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

  // Maps tipsType to a badge color
  Color _getTipTypeColor(String tipsType) {
    switch (tipsType.toLowerCase()) {
      case 'quote':
        return AppColors.accentBlue;
      case 'tip':
        return AppColors.primary;
      case 'video':
        return Colors.yellow.shade700;
      case 'audio':
        return Colors.purple.shade400;
      case 'exercise':
        return Colors.green.shade700;
      case 'article':
        return Colors.blueGrey.shade400;
      case 'image':
        return Colors.orange.shade400;
      case 'reminder':
        return Colors.red.shade400;
      case 'challenge':
        return Colors.teal.shade400;
      default:
        return AppColors.lightTextSecondary;
    }
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
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                ? [AppColors.darkSurface.withOpacity(0.9), AppColors.darkSurface.withOpacity(0.7)]
                : [AppColors.lightSurface, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.shadow : AppColors.shadow.withOpacity(0.08),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
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
                    blurRadius: 4.r,
                    offset: Offset(2.w, 2.h),
                  ),
                ],
              ),
              child: Icon(
                _getTipTypeIcon(tip.tipsType),
                color: AppColors.primary,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tip.tipsTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 20.sp,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _getTipTypeColor(tip.tipsType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          tip.tipsType.capitalize(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getTipTypeColor(tip.tipsType),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    tip.tipsDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontFamily: 'Roboto',
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                    SizedBox(height: 8.h),
                  ],
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
                  SizedBox(height: 16.h),
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
                        child: ElevatedButton(
                          onPressed: () => _editTip(tip),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            elevation: 2,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.penToSquare,
                                  size: 12.sp,
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
                        child: ElevatedButton(
                          onPressed: () => _deleteTip(tip.tipsId, tip.tipsTitle),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            elevation: 2,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.error, AppColors.error.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.trash,
                                  size: 12.sp,
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
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  elevation: 0,
                  pinned: true,
                  floating: false,
                  snap: false,
                  title: Text(
                    AppStrings.manageTipsTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
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
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    color: isDark ? AppColors.darkBackground : Colors.grey.shade50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: isDark
                            ? []
                            : [
                          BoxShadow(
                            color: AppColors.shadow.withOpacity(0.08),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppStrings.searchTipsHint,
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.w),
                          ),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  sliver: StreamBuilder<QuerySnapshot>(
                    key: ValueKey(_reloadKey),
                    stream: _firestore.collection('tips').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            if (index >= tips.length) return const SizedBox.shrink();
                            return _buildTipCard(tips[index], index);
                          },
                          childCount: tips.length,
                        ),
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
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: AnimationController(
              duration: const Duration(milliseconds: 400),
              vsync: this,
            )..forward(),
            curve: Curves.easeOut,
          ),
        ),
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
                  color: AppColors.shadow.withOpacity(0.08),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(Icons.add, color: AppColors.lightBackground, size: 28.sp),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}