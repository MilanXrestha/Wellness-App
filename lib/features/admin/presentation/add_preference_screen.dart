import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';

class AddPreferenceScreen extends StatefulWidget {
  const AddPreferenceScreen({super.key});

  @override
  State<AddPreferenceScreen> createState() => _AddPreferenceScreenState();
}

class _AddPreferenceScreenState extends State<AddPreferenceScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _iconUrlController = TextEditingController();
  final CloudinaryPublic _cloudinary = CloudinaryPublic('dczb26ev1', 'Wellness_App', cache: true);
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedIcon;
  String? _uploadedIconUrl;
  bool _isLoading = false;
  bool _useIconUpload = false;
  PreferenceModel? _preference;
  late AnimationController _saveButtonController;
  bool _isSvg = false;

  @override
  void initState() {
    super.initState();
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PreferenceModel) {
        setState(() {
          _preference = args;
          _nameController.text = args.preferenceName;
          _descriptionController.text = args.preferenceDescription;
          _iconUrlController.text = args.preferenceIcon;
          _useIconUpload = false;
          _isSvg = args.preferenceIcon.toLowerCase().endsWith('.svg');
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconUrlController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      CustomBottomSheet.show(context: context, message: message, isSuccess: false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Preference name is required');
      return false;
    }
    if (_nameController.text.trim().length > 50) {
      _showError('Preference name must be 50 characters or less');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Preference description is required');
      return false;
    }
    if (_descriptionController.text.trim().length > 200) {
      _showError('Preference description must be 200 characters or less');
      return false;
    }
    if (_useIconUpload && _pickedIcon == null && _uploadedIconUrl == null) {
      _showError('Please select an icon to upload');
      return false;
    }
    if (!_useIconUpload && _iconUrlController.text.trim().isEmpty) {
      _showError('Icon URL is required');
      return false;
    }
    return true;
  }

  Future<void> _pickIcon() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedIcon = pickedFile;
          _uploadedIconUrl = null;
          _isSvg = pickedFile.path.toLowerCase().endsWith('.svg');
        });
      }
    } catch (e) {
      _showError('Error picking icon: $e');
    }
  }

  Future<String?> _uploadIcon({String? publicId}) async {
    if (_pickedIcon == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedIcon!.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'preferences',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showError('Error uploading icon: $e');
      return null;
    }
  }

  Future<void> _savePreference() async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);

    try {
      String? iconUrl;
      if (_useIconUpload) {
        final publicId = _preference != null ? _preference!.preferenceId : null;
        iconUrl = await _uploadIcon(publicId: publicId);
        if (iconUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      } else {
        iconUrl = _iconUrlController.text.trim();
      }

      final preferenceData = {
        'preferenceName': _nameController.text.trim(),
        'preferenceDescription': _descriptionController.text.trim(),
        'preferenceIcon': iconUrl,
        'isSvg': iconUrl.toLowerCase().endsWith('.svg'),
      };

      if (_preference == null) {
        await _firestore.collection('preferences').add(preferenceData);
        CustomBottomSheet.show(
          context: context,
          message: 'Preference added successfully!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        await _firestore.collection('preferences').doc(_preference!.preferenceId).update(preferenceData);
        CustomBottomSheet.show(
          context: context,
          message: 'Preference updated successfully!',
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

  Widget _buildIconPreview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.primary : AppColors.lightTextSecondary.withAlpha(153); // Gray border in light mode

    return Center(
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.w), // Thinner border
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withAlpha(50), // Minimal shadow
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: _useIconUpload && _pickedIcon != null
              ? _isSvg
              ? SvgPicture.file(
            File(_pickedIcon!.path),
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => Icon(
              Icons.broken_image,
              color: AppColors.error,
              size: 100.sp,
            ),
          )
              : Image.file(
            File(_pickedIcon!.path),
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image,
              color: AppColors.error,
              size: 100.sp,
            ),
          )
              : _iconUrlController.text.isNotEmpty
              ? _iconUrlController.text.toLowerCase().endsWith('.svg')
              ? SvgPicture.network(
            _iconUrlController.text,
            width: 100.w,
            height: 100.h,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => Icon(
              Icons.broken_image,
              color: AppColors.error,
              size: 100.sp,
            ),
          )
              : Image.network(
            _iconUrlController.text,
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
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            size: 100.sp,
          ),
        ),
      ),
    );
  }

  Widget customSelectableChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final selectedBgColor = isDark
        ? AppColors.primary.withOpacity(0.2)
        : AppColors.lightTextPrimary.withOpacity(0.1); // Subtle gray for selected in light mode
    final unselectedBgColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;
    final textColor = isDark
        ? (selected ? AppColors.primary : AppColors.darkTextPrimary)
        : (selected ? AppColors.lightTextPrimary : AppColors.lightTextPrimary); // Black text
    final borderColor = isDark
        ? (selected ? AppColors.primary : Colors.transparent)
        : (selected ? AppColors.lightTextPrimary : AppColors.lightTextSecondary); // Black or gray border

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? selectedBgColor : unselectedBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: borderColor,
            width: 1.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            if (selected) ...[
              SizedBox(width: 6.w),
              Icon(
                Icons.check,
                color: isDark ? Colors.white : AppColors.lightTextPrimary, // Black check in light mode
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
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary; // Black in light mode
    final iconColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary; // Black icons in light mode
    final saveButtonColors = isDark
        ? [
      AppColors.primary,
      AppColors.primary.withOpacity(0.6),
    ]
        : [
      AppColors.lightTextPrimary,
      AppColors.lightTextPrimary.withOpacity(0.6),
    ]; // Black gradient in light mode
    final labelColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary; // Black labels in light mode
    final dottedColor = isDark ? AppColors.primary : AppColors.lightTextSecondary; // Gray dotted in light mode

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
            color: iconColor, // Black in light mode
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _preference == null ? AppStrings.addPreferenceTitle : AppStrings.editPreferenceTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
            color: titleColor, // Black in light mode
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              size: 26.sp,
              color: iconColor, // Black in light mode
            ),
            onPressed: _savePreference,
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
                    'Preference Name',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: labelColor, // Black in light mode
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: AppStrings.preferenceNameHint,
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
                    'Preference Description',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: labelColor, // Black in light mode
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppStrings.preferenceDescriptionHint,
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
                    'Icon Source',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: labelColor, // Black in light mode
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      customSelectableChip(
                        label: 'Upload from Device',
                        selected: _useIconUpload,
                        onTap: () {
                          setState(() {
                            _useIconUpload = true;
                            _iconUrlController.clear();
                          });
                        },
                        isDark: isDark,
                      ),
                      SizedBox(width: 8.w),
                      customSelectableChip(
                        label: 'Enter URL',
                        selected: !_useIconUpload,
                        onTap: () {
                          setState(() {
                            _useIconUpload = false;
                            _pickedIcon = null;
                            _uploadedIconUrl = null;
                            _isSvg = false;
                          });
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (_useIconUpload)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickIcon,
                          child: DottedBorder(
                            color: dottedColor, // Gray in light mode
                            strokeWidth: 1, // Thinner for minimalism
                            dashPattern: const [8, 4],
                            borderType: BorderType.RRect,
                            radius: Radius.circular(12.r),
                            child: Container(
                              width: double.infinity,
                              height: _pickedIcon == null ? 120.h : 150.h,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: _pickedIcon == null
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 40.sp, color: iconColor), // Black icon in light
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Tap to choose icon (PNG or SVG)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 16.sp,
                                      color: iconColor, // Black text in light
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                                  : _isSvg
                                  ? SvgPicture.file(
                                File(_pickedIcon!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholderBuilder: (_) => Icon(
                                  Icons.broken_image,
                                  color: AppColors.error,
                                  size: 100.sp,
                                ),
                              )
                                  : Image.file(
                                File(_pickedIcon!.path),
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
                          controller: _iconUrlController,
                          decoration: InputDecoration(
                            hintText: 'Enter icon URL (PNG or SVG)',
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (_iconUrlController.text.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          _buildIconPreview(),
                        ],
                      ],
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
                        onTap: _savePreference,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 35.w, vertical: 15.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: saveButtonColors, // Black in light mode
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withAlpha(50), // Minimal shadow
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Text(
                            'Save Preference',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 14.sp,
                              color: AppColors.lightBackground, // White text
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
                child: Center(child: CircularProgressIndicator(color: isDark ? AppColors.primary : AppColors.lightTextPrimary)), // Black spinner in light mode if desired
              ),
          ],
        ),
      ),
    );
  }
}