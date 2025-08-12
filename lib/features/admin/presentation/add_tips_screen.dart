import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../tips/data/models/tips_model.dart';

class AddTipScreen extends StatefulWidget {
  const AddTipScreen({super.key});

  @override
  State<AddTipScreen> createState() => _AddTipScreenState();
}

class _AddTipScreenState extends State<AddTipScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _authorIconUrlController = TextEditingController();
  final CloudinaryPublic _cloudinary = CloudinaryPublic('dczb26ev1', 'Wellness_App', cache: true);
  final ImagePicker _picker = ImagePicker();
  final List<String> tipsTypes = [
    'quote',
    'tip',
    'healthTips',
    'video',
    'audio',
    'exercise',
    'article',
    'image',
    'reminder',
    'challenge',
  ];
  String? _selectedType;
  String? _selectedCategoryId;
  final List<String> _selectedPreferenceIds = [];
  XFile? _pickedAuthorIcon;
  String? _uploadedAuthorIconUrl;
  bool _useAuthorIconUpload = false;
  bool _isFeatured = false;
  bool _isPremium = false;
  final Map<String, CategoryModel> _categoryCache = {};
  final Map<String, PreferenceModel> _preferenceCache = {};
  bool _isLoading = false;
  bool _isDataLoaded = false;
  TipModel? _tip;
  late AnimationController _saveButtonController;

  @override
  void initState() {
    super.initState();
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _loadData();
    // Check if editing an existing tip
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is TipModel) {
        setState(() {
          _tip = args;
          _titleController.text = args.tipsTitle;
          _descriptionController.text = args.tipsDescription;
          _authorController.text = args.tipsAuthor;
          _authorIconUrlController.text = args.authorIcon ?? '';
          _selectedType = tipsTypes.contains(args.tipsType) ? args.tipsType : null;
          _selectedCategoryId = args.categoryId;
          _selectedPreferenceIds.addAll(args.preferenceIds);
          _isFeatured = args.isFeatured;
          _isPremium = args.isPremium;
          _useAuthorIconUpload = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _authorIconUrlController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  // Loads categories and preferences from Firestore
  Future<void> _loadData() async {
    try {
      final categorySnapshot = await _firestore.collection('categories').get();
      final preferenceSnapshot = await _firestore.collection('preferences').get();

      // Load categories with duplicate detection
      for (var doc in categorySnapshot.docs) {
        if (!_categoryCache.containsKey(doc.id)) {
          _categoryCache[doc.id] = CategoryModel.fromFirestore(doc.data(), doc.id);
        } else {
          print('Duplicate category ID found: ${doc.id}');
        }
      }

      // Load preferences
      for (var doc in preferenceSnapshot.docs) {
        _preferenceCache[doc.id] = PreferenceModel.fromFirestore(doc.data(), doc.id);
      }

      // Validate _selectedCategoryId
      if (_tip != null && !_categoryCache.containsKey(_selectedCategoryId)) {
        print('Invalid categoryId: $_selectedCategoryId, resetting to null');
        _selectedCategoryId = null;
      }

      // Log category cache for debugging
      print('Category Cache: ${_categoryCache.keys.toList()}');
      setState(() => _isDataLoaded = true);
    } catch (e) {
      _showError('${AppStrings.error} $e');
    }
  }

  // Shows error message in CustomBottomSheet
  void _showError(String message) {
    if (mounted) {
      CustomBottomSheet.show(context: context, message: message, isSuccess: false);
    }
  }

  // Validates form fields
  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showError('Tip title is required');
      return false;
    }
    if (_titleController.text.trim().length > 500) {
      _showError('Tip title must be 100 characters or less');
      return false;
    }
    if (_descriptionController.text.trim().length > 500) {
      _showError('Tip description must be 500 characters or less');
      return false;
    }
    if (_selectedType == null) {
      _showError('Tip type is required');
      return false;
    }
    if (_authorController.text.trim().length > 50) {
      _showError('Author name must be 50 characters or less');
      return false;
    }
    if (!_useAuthorIconUpload && _authorIconUrlController.text.trim().toLowerCase().endsWith('.svg')) {
      _showError('SVG is not supported for author icon');
      return false;
    }
    if (_selectedCategoryId == null) {
      _showError('Category is required');
      return false;
    }
    if (_selectedPreferenceIds.isEmpty) {
      _showError('At least one preference is required');
      return false;
    }
    return true;
  }

  // Picks an author icon from device
  Future<void> _pickAuthorIcon() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (pickedFile.path.toLowerCase().endsWith('.svg')) {
          _showError('SVG files are not supported for author icon');
          return;
        }
        setState(() {
          _pickedAuthorIcon = pickedFile;
          _uploadedAuthorIconUrl = null;
        });
      }
    } catch (e) {
      _showError('Error picking author icon: $e');
    }
  }

  // Uploads author icon to Cloudinary
  Future<String?> _uploadAuthorIcon({String? publicId}) async {
    if (_pickedAuthorIcon == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedAuthorIcon!.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'tips_author_icons',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showError('Error uploading author icon: $e');
      return null;
    }
  }

  // Saves or updates tip
  Future<void> _saveTip() async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);

    try {
      String? authorIconUrl;
      if (_useAuthorIconUpload && _pickedAuthorIcon != null) {
        final publicId = _tip != null ? _tip!.tipsId : null;
        authorIconUrl = await _uploadAuthorIcon(publicId: publicId);
      } else if (_authorIconUrlController.text.trim().isNotEmpty) {
        authorIconUrl = _authorIconUrlController.text.trim();
      }

      final tipData = {
        'tipsTitle': _titleController.text.trim(),
        'tipsDescription': _descriptionController.text.trim(),
        'tipsType': _selectedType,
        'tipsAuthor': _authorController.text.trim(),
        if (authorIconUrl != null) 'authorIcon': authorIconUrl,
        'categoryId': _selectedCategoryId,
        'preferenceIds': _selectedPreferenceIds,
        'createdAt': _tip == null ? FieldValue.serverTimestamp() : _tip!.createdAt,
        'isFeatured': _isFeatured,
        'isPremium': _isPremium,
      };

      if (_tip == null) {
        // Add new tip
        await _firestore.collection('tips').add(tipData);
        CustomBottomSheet.show(
          context: context,
          message: 'Tip added successfully!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        // Update existing tip
        await _firestore.collection('tips').doc(_tip!.tipsId).update(tipData);
        CustomBottomSheet.show(
          context: context,
          message: 'Tip updated successfully!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showError('${AppStrings.error} $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Builds author icon preview
  Widget _buildAuthorIconPreview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2.w),
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
          child: _useAuthorIconUpload && _pickedAuthorIcon != null
              ? Image.file(
            File(_pickedAuthorIcon!.path),
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image,
              color: AppColors.error,
              size: 100.sp,
            ),
          )
              : _authorIconUrlController.text.isNotEmpty
              ? Image.network(
            _authorIconUrlController.text,
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image,
              color: AppColors.error,
              size: 100.sp,
            ),
          )
              : Icon(
            Icons.image_outlined,
            color: AppColors.darkTextSecondary,
            size: 100.sp,
          ),
        ),
      ),
    );
  }

  // Builds preference chips using customSelectableChip
  List<Widget> _buildPreferenceChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _preferenceCache.entries.map((entry) {
      final pref = entry.value;
      final isSelected = _selectedPreferenceIds.contains(entry.key);
      return customSelectableChip(
        label: pref.preferenceName,
        selected: isSelected,
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedPreferenceIds.remove(entry.key);
            } else {
              _selectedPreferenceIds.add(entry.key);
            }
          });
        },
        isDark: isDark,
      );
    }).toList();
  }

  // Custom selectable chip with white check icon on selected
  Widget customSelectableChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.2)
              : isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.primary
                    : isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            if (selected) ...[
              SizedBox(width: 6.w),
              Icon(
                Icons.check,
                color: Colors.white, // White tick
                size: 16.sp,
              ),
            ],
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20.sp,
            color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tip == null ? AppStrings.addTipTitle : AppStrings.editTipTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
            color: isDark ? AppColors.darkTextPrimary : AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              size: 26.sp,
              color: AppColors.lightBackground,
            ),
            onPressed: _saveTip,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tip Title
                  Text(
                    'Tip Title',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: AppStrings.tipsTitleHint,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Tip Description
                  Text(
                    'Tip Description',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppStrings.tipsDescriptionHint,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Tip Type
                  Text(
                    'Tip Type',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    hint: Text(AppStrings.tipsTypeHint),
                    items: tipsTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type.capitalize()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Tip Author
                  Text(
                    'Tip Author',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      hintText: AppStrings.tipsAuthorHint,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Author Icon
                  Text(
                    'Author Icon',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      customSelectableChip(
                        label: 'Upload from Device',
                        selected: _useAuthorIconUpload,
                        onTap: () {
                          setState(() {
                            _useAuthorIconUpload = true;
                            _authorIconUrlController.clear();
                          });
                        },
                        isDark: isDark,
                      ),
                      SizedBox(width: 8.w),
                      customSelectableChip(
                        label: 'Enter URL',
                        selected: !_useAuthorIconUpload,
                        onTap: () {
                          setState(() {
                            _useAuthorIconUpload = false;
                            _pickedAuthorIcon = null;
                            _uploadedAuthorIconUrl = null;
                          });
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (_useAuthorIconUpload)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickAuthorIcon,
                          child: DottedBorder(
                            color: AppColors.primary,
                            strokeWidth: 2,
                            dashPattern: const [8, 4],
                            borderType: BorderType.RRect,
                            radius: Radius.circular(12.r),
                            child: Container(
                              width: double.infinity,
                              height: _pickedAuthorIcon == null ? 120.h : 150.h,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: _pickedAuthorIcon == null
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 40.sp, color: AppColors.primary),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Tap to choose icon (PNG or JPEG)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                                  : Image.file(
                                File(_pickedAuthorIcon!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image,
                                  color: AppColors.error,
                                  size: 100.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _authorIconUrlController,
                          decoration: InputDecoration(
                            hintText: 'Enter icon URL (PNG or JPEG)',
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (_authorIconUrlController.text.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          _buildAuthorIconPreview(),
                        ],
                      ],
                    ),
                  SizedBox(height: 16.h),
                  // Category
                  Text(
                    'Category',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _categoryCache.isEmpty
                      ? Text(
                    'No categories available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: AppColors.error,
                    ),
                  )
                      : DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    hint: Text(AppStrings.categoryHint),
                    items: _categoryCache.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value.categoryName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Featured
                  SwitchListTile(
                    title: Text(
                      'Featured',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() => _isFeatured = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  // Premium
                  SwitchListTile(
                    title: Text(
                      'Premium',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    value: _isPremium,
                    onChanged: (value) {
                      setState(() => _isPremium = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  SizedBox(height: 16.h),
                  // Preferences
                  Text(
                    'Preferences',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: _buildPreferenceChips(),
                  ),
                  SizedBox(height: 24.h),
                  // Save Button
                  Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _saveButtonController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _saveTip,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 15.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
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
                          child: Text(
                            'Save Tip',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.lightBackground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}