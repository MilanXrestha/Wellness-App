import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For direct Firebase updates
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // Added for Provider
import 'package:wellness_app/core/resources/colors.dart'; // Ensure this is imported for AppColors
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/common/widgets/custom_cropper_screen.dart';

import '../../providers/user_provider.dart'; // Assuming this is your custom cropper widget

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final CloudinaryPublic _cloudinary = CloudinaryPublic('dczb26ev1', 'Wellness_App', cache: true);
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  bool _isSaving = false;
  String? _errorMessage; // For form validation error
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  double _avatarScale = 1.0; // For avatar tap animation

  @override
  void initState() {
    super.initState();
    // Fade animation for smooth entry
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _refreshUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshUserProfile() async {
    // Use Provider to get the latest user
    final userProvider = context.read<UserProvider>();
    await userProvider.refreshUser();
    final user = userProvider.user;
    setState(() {
      _nameController.text = user?.displayName ?? 'User';
      _uploadedImageUrl = user?.photoURL;
    });
  }

  Future<bool> _requestPhotoPermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }
    if (status.isGranted) return true;

    status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showSnackBar('Photo library access denied. Please enable in settings.', AppColors.error);
      await openAppSettings();
      return false;
    }
    _showSnackBar('Photo library access denied.', AppColors.error);
    return false;
  }

  Future<void> _pickImage() async {
    try {
      if (!await _requestPhotoPermission()) return;

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return; // User cancelled

      final croppedFile = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomCropperScreen(imageFile: File(pickedFile.path)),
        ),
      );

      if (croppedFile != null) {
        setState(() {
          _pickedImage = XFile(croppedFile.path);
          _uploadedImageUrl = null; // Reset uploaded URL when new image is picked
          _errorMessage = null; // Clear any error messages
        });
      }
    } catch (e) {
      _showSnackBar('Error picking or cropping image: $e', AppColors.error);
    }
  }

  Future<void> _confirmDeleteProfilePicture() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Delete',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your profile picture?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _pickedImage = null;
        _uploadedImageUrl = null;
        _errorMessage = null; // Clear errors
      });
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(_nameController.text.trim());
          await user.updatePhotoURL(null); // Explicitly set photoURL to null
          await user.reload();
        }
        // Trigger provider refresh to notify all listeners
        await context.read<UserProvider>().refreshUser();
        _showSnackBar('Profile picture removed successfully!', AppColors.primary);
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay for propagation
        if (context.mounted) Navigator.pop(context); // No need for result; Provider handles refresh
      } catch (e) {
        _showSnackBar('Error removing profile picture: ${e.toString().replaceFirst('Exception: ', '')}', AppColors.error);
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedImage!.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'profile',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showSnackBar('Error uploading image: $e', AppColors.error);
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Username is required';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null; // Clear any error messages
    });
    try {
      String? photoUrl = _uploadedImageUrl;
      if (_pickedImage != null) {
        photoUrl = await _uploadImage();
        if (photoUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.updatePhotoURL(photoUrl); // Handles null properly
        await user.reload();
      }
      // Trigger provider refresh to notify all listeners
      await context.read<UserProvider>().refreshUser();
      _showSnackBar('Profile updated successfully!', AppColors.primary);
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for propagation
      if (context.mounted) Navigator.pop(context); // No need for result; Provider handles refresh
    } catch (e) {
      _showSnackBar('Error updating profile: ${e.toString().replaceFirst('Exception: ', '')}', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: AppColors.lightBackground, // White text for contrast
            fontSize: 14.sp,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.lightBackground,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final hasImage = _pickedImage != null || (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor, // Use theme background for consistency
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(64.h),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Container(
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: isDarkMode
                          ? []
                          : [
                        BoxShadow(
                          color: AppColors.lightTextPrimary.withOpacity(0.2),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            size: 24.sp,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Back',
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Edit Profile',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              size: 24.sp,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            onPressed: null, // Dummy for symmetry
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h), // Increased vertical padding for breathing room
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4, // Reduced for subtler shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(
                          color: isDarkMode ? AppColors.primary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.3), // Gray border in light mode for black/white vibe
                          width: 0.5.w, // Thinner border
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface, // Themed surface color
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.all(24.w), // Increased padding for better spacing
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTapDown: (_) => setState(() => _avatarScale = 0.95),
                              onTapUp: (_) {
                                setState(() => _avatarScale = 1.0);
                                _pickImage();
                              },
                              onTapCancel: () => setState(() => _avatarScale = 1.0),
                              child: AnimatedScale(
                                scale: _avatarScale,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 50.w,
                                      backgroundImage: _pickedImage != null
                                          ? FileImage(File(_pickedImage!.path))
                                          : _uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty
                                          ? NetworkImage(_uploadedImageUrl!)
                                          : null,
                                      backgroundColor: AppColors.primary.withOpacity(0.2),
                                      child: !hasImage // Only show placeholder if no image
                                          ? Icon(
                                        Icons.person,
                                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        size: 50.sp,
                                      )
                                          : null, // No child icon if there's an image
                                    ),
                                    if (hasImage) // Edit badge overlay only if there's an image
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? AppColors.primary.withOpacity(0.7) : AppColors.lightTextPrimary.withOpacity(0.7), // Black with opacity in light mode
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20.sp,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h), // Increased spacing
                            Text(
                              hasImage ? 'Tap to change image' : 'Tap to select and crop image',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 14.sp,
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (hasImage) ...[
                              SizedBox(height: 12.h),
                              OutlinedButton(
                                onPressed: _confirmDeleteProfilePicture,
                                style: theme.outlinedButtonTheme.style?.copyWith(
                                  side: WidgetStateProperty.all(
                                    BorderSide(color: theme.colorScheme.error, width: 1.w),
                                  ),
                                  foregroundColor: WidgetStateProperty.all(theme.colorScheme.error),
                                ),
                                child: Text(
                                  'Delete Profile Picture',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 14.sp,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 24.h), // Increased spacing
                            TextField(
                              controller: _nameController,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 16.sp,
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontFamily: 'Poppins',
                              ),
                              decoration: InputDecoration(
                                labelText: 'Edit Username',
                                hintText: 'Enter your username',
                                labelStyle: theme.inputDecorationTheme.labelStyle?.copyWith(
                                  fontSize: 16.sp,
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(
                                  fontSize: 16.sp,
                                  color: isDarkMode ? AppColors.darkTextSecondary.withOpacity(0.6) : AppColors.lightTextSecondary.withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface, // Themed fill color
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? AppColors.primary.withOpacity(0.5) : AppColors.lightTextSecondary.withOpacity(0.5),
                                    width: 1.w,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? AppColors.primary.withOpacity(0.5) : AppColors.lightTextSecondary.withOpacity(0.5),
                                    width: 1.w,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
                                    width: 1.5.w,
                                  ),
                                ),
                                errorText: _errorMessage, // Show validation error
                                errorStyle: TextStyle(color: AppColors.error, fontSize: 12.sp),
                              ),
                            ),
                            SizedBox(height: 24.h), // Increased spacing
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Cancel Button (Outlined with border)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Feedback.forTap(context); // Haptic feedback
                                      Navigator.pop(context);
                                    },
                                    child: AnimatedScale(
                                      scale: 1.0, // Can add press scale if desired
                                      duration: const Duration(milliseconds: 200),
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: theme.outlinedButtonTheme.style?.copyWith(
                                          backgroundColor: WidgetStateProperty.all(
                                            isDarkMode ? AppColors.darkSecondary : AppColors.lightBackground, // White in light mode
                                          ),
                                          foregroundColor: WidgetStateProperty.all(
                                            isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, // Black text in light mode
                                          ),
                                          side: WidgetStateProperty.all(
                                            BorderSide(
                                              color: isDarkMode ? AppColors.primary : AppColors.lightTextSecondary, // Gray border in light mode
                                              width: 1.w,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Cancel',
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            fontSize: 16.sp,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                // Save Button (Filled with gradient and subtle border/shadow)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isSaving ? null : () {
                                      Feedback.forTap(context); // Haptic feedback
                                      _saveProfile();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      transform: Matrix4.identity()..scale(_isSaving ? 0.95 : 1.0),
                                      child: ElevatedButton(
                                        onPressed: _isSaving ? null : _saveProfile,
                                        style: theme.elevatedButtonTheme.style?.copyWith(
                                          backgroundColor: WidgetStateProperty.all(
                                            isDarkMode ? AppColors.primary : AppColors.lightTextPrimary, // Black background in light mode
                                          ),
                                          foregroundColor: WidgetStateProperty.all(
                                            isDarkMode ? AppColors.darkTextPrimary : AppColors.lightBackground, // White text in light mode
                                          ),
                                          overlayColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.1)), // Subtle overlay
                                          shape: WidgetStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                              side: BorderSide(
                                                color: AppColors.primary.withOpacity(0.5), // Subtle green border accent
                                                width: 0.5.w, // Thin border
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: _isSaving
                                            ? SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: CircularProgressIndicator(
                                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightBackground,
                                            strokeWidth: 2.w,
                                          ),
                                        )
                                            : Text(
                                          'Save',
                                          style: theme.textTheme.labelLarge?.copyWith(
                                            fontSize: 16.sp,
                                            fontFamily: 'Poppins',
                                            color: AppColors.lightBackground,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}