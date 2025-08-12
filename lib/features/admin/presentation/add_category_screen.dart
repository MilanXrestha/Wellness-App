import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final CloudinaryPublic _cloudinary = CloudinaryPublic('dczb26ev1', 'Wellness_App', cache: true);
  final ImagePicker _picker = ImagePicker();
  final Map<String, PreferenceModel> _preferenceCache = {};
  final List<String> _selectedPreferenceIds = [];
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  bool _isPrefsLoaded = false;
  bool _useImageUpload = false;
  CategoryModel? _category;
  late AnimationController _saveButtonController;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    // Check if editing an existing category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is CategoryModel) {
        setState(() {
          _category = args;
          _nameController.text = args.categoryName;
          _descriptionController.text = args.categoryDescription!;
          _imageUrlController.text = args.imageUrl;
          _selectedPreferenceIds.addAll(args.preferenceIds);
          _useImageUpload = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final snapshot = await _firestore.collection('preferences').get();
      for (var doc in snapshot.docs) {
        _preferenceCache[doc.id] = PreferenceModel.fromFirestore(doc.data(), doc.id);
      }
      setState(() {
        _isPrefsLoaded = true;
      });
    } catch (e) {
      _showError('${AppStrings.error} $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      CustomBottomSheet.show(context: context, message: message, isSuccess: false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Category name is required');
      return false;
    }
    if (_nameController.text.trim().length > 50) {
      _showError('Category name must be 50 characters or less');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Category description is required');
      return false;
    }
    if (_descriptionController.text.trim().length > 200) {
      _showError('Category description must be 200 characters or less');
      return false;
    }
    if (_useImageUpload && _pickedImage == null && _uploadedImageUrl == null) {
      _showError('Please select an image to upload');
      return false;
    }
    if (!_useImageUpload && _imageUrlController.text.trim().isEmpty) {
      _showError('Image URL is required');
      return false;
    }
    if (_selectedPreferenceIds.isEmpty) {
      _showError('Please select at least one preference');
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
          _uploadedImageUrl = null; // Reset uploaded URL
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedImage!.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'categories',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showError('Error uploading image: $e');
      return null;
    }
  }


  Future<void> _saveCategory() async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_useImageUpload) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      } else {
        imageUrl = _imageUrlController.text.trim();
      }

      final categoryData = {
        'categoryName': _nameController.text.trim(),
        'categoryDescription': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'preferenceIds': _selectedPreferenceIds,
      };

      if (_category == null) {
        // Add new category
        await _firestore.collection('categories').add(categoryData);
        CustomBottomSheet.show(
          context: context,
          message: 'Category added successfully!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        // Update existing category
        await _firestore.collection('categories').doc(_category!.categoryId).update(categoryData);
        CustomBottomSheet.show(
          context: context,
          message: 'Category updated successfully!',
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

  List<Widget> _buildPreferenceChips() {
    return _preferenceCache.entries.map((entry) {
      final pref = entry.value;
      final isSelected = _selectedPreferenceIds.contains(entry.key);
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedPreferenceIds.remove(entry.key);
            } else {
              _selectedPreferenceIds.add(entry.key);
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          margin: EdgeInsets.only(right: 6.w, bottom: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.primary.withAlpha(77),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pref.preferenceName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.sp,
                  fontFamily: 'Poppins',
                  color: isSelected ? AppColors.primary : AppColors.darkTextPrimary,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: 4.w),
                Icon(
                  Icons.check,
                  size: 12.sp,
                  color: AppColors.lightBackground,
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildImagePreview() {
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
          child: _useImageUpload && _pickedImage != null
              ? Image.file(
            File(_pickedImage!.path),
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image,
              color: AppColors.error,
              size: 100.sp,
            ),
          )
              : _imageUrlController.text.isNotEmpty
              ? Image.network(
            _imageUrlController.text,
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
                color: selected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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

    if (!_isPrefsLoaded) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
          _category == null ? AppStrings.addCategoryTitle : AppStrings.editCategoryTitle,
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
            onPressed: _saveCategory,
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
                  Text(
                    'Category Name',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: AppStrings.categoryNameHint,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Category Description',
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
                      hintText: AppStrings.categoryDescriptionHint,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Image Source',
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
                        selected: _useImageUpload,
                        onTap: () {
                          setState(() {
                            _useImageUpload = true;
                            _imageUrlController.clear();
                          });
                        },
                        isDark: isDark,
                      ),
                      SizedBox(width: 8.w),
                      customSelectableChip(
                        label: 'Enter URL',
                        selected: !_useImageUpload,
                        onTap: () {
                          setState(() {
                            _useImageUpload = false;
                            _pickedImage = null;
                            _uploadedImageUrl = null;
                          });
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (_useImageUpload)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: DottedBorder(
                            color: AppColors.primary,
                            strokeWidth: 2,
                            dashPattern: const [8, 4],
                            borderType: BorderType.RRect,
                            radius: Radius.circular(12.r),
                            child: Container(
                              width: double.infinity,
                              height: _pickedImage == null ? 120.h : 300.h,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: _pickedImage == null
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 40.sp, color: AppColors.primary),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Tap to choose image',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                                  : ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )

                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _imageUrlController,
                          decoration: InputDecoration(
                            hintText: 'Enter image URL',
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (_imageUrlController.text.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          _buildImagePreview(),
                        ],
                      ],
                    ),
                  SizedBox(height: 16.h),
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
                  Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _saveButtonController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _saveCategory,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 15.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.6),
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
                          child: Text(
                            'Save Category',
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
