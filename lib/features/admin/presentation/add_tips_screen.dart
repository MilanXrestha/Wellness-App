import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

class AddTipScreen extends StatefulWidget {
  const AddTipScreen({super.key});

  @override
  State<AddTipScreen> createState() => _AddTipScreenState();
}

class _AddTipScreenState extends State<AddTipScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _authorIconUrlController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _audioUrlController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _thumbnailUrlController = TextEditingController();
  final TextEditingController _mediaDurationController = TextEditingController();
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dczb26ev1',
    'Wellness_App',
    cache: true,
  );
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
  XFile? _pickedVideo;
  PlatformFile? _pickedAudio;
  XFile? _pickedImage;
  XFile? _pickedThumbnail;
  bool _useVideoUpload = false;
  bool _useAudioUpload = false;
  bool _useImageUpload = false;
  bool _useThumbnailUpload = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is TipModel) {
        setState(() {
          _tip = args;
          _titleController.text = args.tipsTitle;
          _descriptionController.text = args.tipsDescription;
          _authorController.text = args.tipsAuthor;
          _authorIconUrlController.text = args.authorIcon ?? '';
          _selectedType = tipsTypes.contains(args.tipsType)
              ? args.tipsType
              : null;
          _selectedCategoryId = args.categoryId;
          _selectedPreferenceIds.addAll(args.preferenceIds);
          _isFeatured = args.isFeatured;
          _isPremium = args.isPremium;
          _useAuthorIconUpload = false;
          _videoUrlController.text = args.videoUrl ?? '';
          _audioUrlController.text = args.audioUrl ?? '';
          _imageUrlController.text = args.imageUrl ?? '';
          _thumbnailUrlController.text = args.thumbnailUrl ?? '';
          _mediaDurationController.text = args.mediaDuration ?? '';
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
    _videoUrlController.dispose();
    _audioUrlController.dispose();
    _imageUrlController.dispose();
    _thumbnailUrlController.dispose();
    _mediaDurationController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  // Loads categories and preferences from Firestore
  Future<void> _loadData() async {
    try {
      final categorySnapshot = await _firestore.collection('categories').get();
      final preferenceSnapshot = await _firestore.collection('preferences').get();

      for (var doc in categorySnapshot.docs) {
        if (!_categoryCache.containsKey(doc.id)) {
          _categoryCache[doc.id] = CategoryModel.fromFirestore(
            doc.data(),
            doc.id,
          );
        } else {
          print('Duplicate category ID found: ${doc.id}');
        }
      }

      for (var doc in preferenceSnapshot.docs) {
        _preferenceCache[doc.id] = PreferenceModel.fromFirestore(
          doc.data(),
          doc.id,
        );
      }

      if (_tip != null && !_categoryCache.containsKey(_selectedCategoryId)) {
        print('Invalid categoryId: $_selectedCategoryId, resetting to null');
        _selectedCategoryId = null;
      }

      setState(() => _isDataLoaded = true);
    } catch (e) {
      _showError('${AppStrings.error} $e');
    }
  }

  // Shows error message in CustomBottomSheet
  void _showError(String message) {
    if (mounted) {
      CustomBottomSheet.show(
        context: context,
        message: message,
        isSuccess: false,
      );
    }
  }

  // Validates form fields based on tip type
  bool _validateForm() {
    if (_selectedType == null) {
      _showError('Tip type is required');
      return false;
    }

    if (_titleController.text.trim().isEmpty && _selectedType != 'image') {
      _showError('Tip title is required');
      return false;
    }

    if (_titleController.text.trim().length > 500) {
      _showError('Tip title must be 500 characters or less');
      return false;
    }

    if (_descriptionController.text.trim().length > 2000) {
      _showError('Tip description must be 2000 characters or less');
      return false;
    }

    // Validation based on tip type
    switch (_selectedType) {
      case 'video':
        if ((_useVideoUpload && _pickedVideo == null) ||
            (!_useVideoUpload && _videoUrlController.text.trim().isEmpty)) {
          _showError('Video URL or file is required');
          return false;
        }
        if ((_useThumbnailUpload && _pickedThumbnail == null) ||
            (!_useThumbnailUpload && _thumbnailUrlController.text.trim().isEmpty)) {
          _showError('Thumbnail is required for video content');
          return false;
        }
        if (_mediaDurationController.text.trim().isEmpty) {
          _showError('Media duration is required for video content');
          return false;
        }
        if (_authorController.text.trim().isEmpty) {
          _showError('Author name is required for video content');
          return false;
        }
        break;

      case 'audio':
        if ((_useAudioUpload && _pickedAudio == null) ||
            (!_useAudioUpload && _audioUrlController.text.trim().isEmpty)) {
          _showError('Audio URL or file is required');
          return false;
        }
        if (_mediaDurationController.text.trim().isEmpty) {
          _showError('Media duration is required for audio content');
          return false;
        }
        if (_authorController.text.trim().isEmpty) {
          _showError('Author name is required for audio content');
          return false;
        }
        break;

      case 'image':
        if ((_useImageUpload && _pickedImage == null) ||
            (!_useImageUpload && _imageUrlController.text.trim().isEmpty)) {
          _showError('Image URL or file is required');
          return false;
        }
        break;

      case 'quote':
      case 'tip':
      case 'healthTips':
        if (_authorController.text.trim().isEmpty) {
          _showError('Author name is required');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showError('Description is required');
          return false;
        }
        break;
    }

    if (_authorController.text.trim().length > 50) {
      _showError('Author name must be 50 characters or less');
      return false;
    }

    if (!_useAuthorIconUpload &&
        _authorIconUrlController.text.trim().isNotEmpty &&
        _authorIconUrlController.text.trim().toLowerCase().endsWith('.svg')) {
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

  // Picks a video from device
  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedVideo = pickedFile;
        });
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  // Picks an audio from device using file_picker
  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedAudio = result.files.single;
        });
      }
    } catch (e) {
      _showError('Error picking audio: $e');
    }
  }

  // Picks an image from device
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  // Picks a thumbnail from device
  Future<void> _pickThumbnail() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedThumbnail = pickedFile;
        });
      }
    } catch (e) {
      _showError('Error picking thumbnail: $e');
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

  // Uploads video to Cloudinary
  Future<String?> _uploadVideo({String? publicId}) async {
    if (_pickedVideo == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedVideo!.path,
        resourceType: CloudinaryResourceType.Video,
        folder: 'tips_videos',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showError('Error uploading video: $e');
      return null;
    }
  }

  // Uploads audio to Cloudinary
  Future<String?> _uploadAudio({String? publicId}) async {
    if (_pickedAudio == null || _pickedAudio!.path == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedAudio!.path!,
        resourceType: CloudinaryResourceType.Video, // Treat audio as video
        folder: 'tips_audios',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showError('Error uploading audio: $e');
      return null;
    }
  }

  // Uploads image to Cloudinary
  Future<String?> _uploadImage({String? publicId}) async {
    if (_pickedImage == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedImage!.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'tips_wallpaper_images',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showError('Error uploading image: $e');
      return null;
    }
  }

  // Uploads thumbnail to Cloudinary
  Future<String?> _uploadThumbnail({String? publicId}) async {
    if (_pickedThumbnail == null) return null;
    try {
      final cloudinaryFile = CloudinaryFile.fromFile(
        _pickedThumbnail!.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'tips_thumbnails',
      );
      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } catch (e) {
      _showError('Error uploading thumbnail: $e');
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

      String? videoUrl;
      String? audioUrl;
      String? imageUrl;
      String? thumbnailUrl;
      String? mediaDuration = _mediaDurationController.text.trim();

      if (_selectedType == 'video') {
        if (_useVideoUpload) {
          videoUrl = await _uploadVideo();
        } else {
          videoUrl = _videoUrlController.text.trim();
        }
        if (_useThumbnailUpload) {
          thumbnailUrl = await _uploadThumbnail();
        } else {
          thumbnailUrl = _thumbnailUrlController.text.trim();
        }
      } else if (_selectedType == 'audio') {
        if (_useAudioUpload) {
          audioUrl = await _uploadAudio();
        } else {
          audioUrl = _audioUrlController.text.trim();
        }

        // For audio, use the thumbnail if provided
        if (_useThumbnailUpload && _pickedThumbnail != null) {
          thumbnailUrl = await _uploadThumbnail();
        } else if (_thumbnailUrlController.text.trim().isNotEmpty) {
          thumbnailUrl = _thumbnailUrlController.text.trim();
        }
      } else if (_selectedType == 'image') {
        if (_useImageUpload) {
          imageUrl = await _uploadImage();
        } else {
          imageUrl = _imageUrlController.text.trim();
        }
      }

      final tipData = {
        'tipsTitle': _titleController.text.trim(),
        'tipsDescription': _descriptionController.text.trim(),
        'tipsType': _selectedType,
        'tipsAuthor': _authorController.text.trim(),
        if (authorIconUrl != null) 'authorIcon': authorIconUrl,
        'categoryId': _selectedCategoryId,
        'preferenceIds': _selectedPreferenceIds,
        'createdAt': _tip == null
            ? FieldValue.serverTimestamp()
            : _tip!.createdAt,
        'isFeatured': _isFeatured,
        'isPremium': _isPremium,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (audioUrl != null) 'audioUrl': audioUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (mediaDuration.isNotEmpty) 'mediaDuration': mediaDuration,
      };

      if (_tip == null) {
        await _firestore.collection('tips').add(tipData);
        CustomBottomSheet.show(
          context: context,
          message: 'Tip added successfully!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
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

  // Custom selectable chip with gradient and white check icon on selected
  Widget customSelectableChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: AnimationController(
            duration: const Duration(milliseconds: 400),
            vsync: this,
          )..forward(),
          curve: Curves.easeOut,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: selected
                  ? [AppColors.primary, AppColors.primary.withOpacity(0.7)]
                  : isDark
                  ? [
                AppColors.darkSurface,
                AppColors.darkSurface.withOpacity(0.7),
              ]
                  : [AppColors.lightSurface, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.3),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.shadow
                    : AppColors.shadow.withOpacity(0.08),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: selected
                      ? AppColors.lightBackground
                      : isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (selected) ...[
                SizedBox(width: 6.w),
                Icon(
                  Icons.check,
                  color: AppColors.lightBackground,
                  size: 14.sp,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Media upload UI
  Widget _buildMediaUploader({
    required String title,
    required bool useUpload,
    required Function() toggleUpload,
    required Function() pickMedia,
    required dynamic pickedMedia,
    required TextEditingController urlController,
    required String uploadHintText,
    required IconData mediaIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeInUp(
      duration: const Duration(milliseconds: 540),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              customSelectableChip(
                label: 'Upload from Device',
                selected: useUpload,
                onTap: toggleUpload,
                isDark: isDark,
              ),
              SizedBox(width: 8.w),
              customSelectableChip(
                label: 'Enter URL',
                selected: !useUpload,
                onTap: () {
                  setState(() {
                    toggleUpload();
                  });
                },
                isDark: isDark,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (useUpload)
            GestureDetector(
              onTap: pickMedia,
              child: DottedBorder(
                color: AppColors.primary,
                strokeWidth: 1.w,
                dashPattern: const [8, 4],
                borderType: BorderType.RRect,
                radius: Radius.circular(12.r),
                child: Container(
                  width: double.infinity,
                  height: pickedMedia == null ? 120.h : 150.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                        AppColors.darkSurface,
                        AppColors.darkSurface.withOpacity(0.7),
                      ]
                          : [
                        AppColors.lightSurface,
                        Colors.grey.shade50,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppColors.shadow
                            : AppColors.shadow.withOpacity(0.08),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: pickedMedia == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mediaIcon,
                        size: 40.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        uploadHintText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                      : _buildMediaPreview(pickedMedia, mediaIcon),
                ),
              ),
            )
          else
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'Enter URL',
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 1.w,
                  ),
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
        ],
      ),
    );
  }

  // Media preview (image, video, audio, thumbnail)
  Widget _buildMediaPreview(dynamic media, IconData defaultIcon) {
    // For XFile (image or video)
    if (media is XFile) {
      final isImage = !media.path.toLowerCase().endsWith('.mp4');
      if (isImage) {
        return Image.file(
          File(media.path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image,
            color: AppColors.error,
            size: 100.sp,
          ),
        );
      } else {
        return Center(
          child: Icon(
            Icons.video_file,
            size: 100.sp,
            color: AppColors.primary,
          ),
        );
      }
    }

    // For PlatformFile (audio)
    if (media is PlatformFile) {
      return Center(
        child: Icon(
          Icons.audio_file,
          size: 100.sp,
          color: AppColors.primary,
        ),
      );
    }

    // Default fallback
    return Center(
      child: Icon(
        defaultIcon,
        size: 100.sp,
        color: AppColors.primary,
      ),
    );
  }

  // Builds form fields for different tip types
  Widget _buildTipFields() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedType == null) return const SizedBox.shrink();

    // Common fields for all types
    List<Widget> fields = [
      // Title Field (for all except image)
      if (_selectedType != 'image' || _titleController.text.isNotEmpty) ...[
        SizedBox(height: 16.h),
        FadeInUp(
          duration: const Duration(milliseconds: 380),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tip Title',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: AppStrings.tipsTitleHint,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.w,
                    ),
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],

      // Description field (for quote, tip, healthTips, video)
      if (_selectedType == 'quote' || _selectedType == 'tip' ||
          _selectedType == 'healthTips' || _selectedType == 'video') ...[
        SizedBox(height: 16.h),
        FadeInUp(
          duration: const Duration(milliseconds: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tip Description',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppStrings.tipsDescriptionHint,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.w,
                    ),
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ];

    // Type-specific fields
    switch (_selectedType) {
      case 'video':
        fields.addAll([
          // Video upload or URL
          SizedBox(height: 16.h),
          _buildMediaUploader(
            title: 'Video Source',
            useUpload: _useVideoUpload,
            toggleUpload: () {
              setState(() {
                _useVideoUpload = !_useVideoUpload;
                if (_useVideoUpload) _videoUrlController.clear();
                else _pickedVideo = null;
              });
            },
            pickMedia: _pickVideo,
            pickedMedia: _pickedVideo,
            urlController: _videoUrlController,
            uploadHintText: 'Tap to choose video',
            mediaIcon: Icons.video_library,
          ),

          // Thumbnail for video
          SizedBox(height: 16.h),
          _buildMediaUploader(
            title: 'Thumbnail Source',
            useUpload: _useThumbnailUpload,
            toggleUpload: () {
              setState(() {
                _useThumbnailUpload = !_useThumbnailUpload;
                if (_useThumbnailUpload) _thumbnailUrlController.clear();
                else _pickedThumbnail = null;
              });
            },
            pickMedia: _pickThumbnail,
            pickedMedia: _pickedThumbnail,
            urlController: _thumbnailUrlController,
            uploadHintText: 'Tap to choose thumbnail',
            mediaIcon: Icons.image,
          ),

          // Media duration
          SizedBox(height: 16.h),
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media Duration',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _mediaDurationController,
                  decoration: InputDecoration(
                    hintText: 'Enter duration (e.g., 5:30)',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.w,
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Author fields
          SizedBox(height: 16.h),
          _buildAuthorFields(theme, isDark),
        ]);
        break;

      case 'audio':
        fields.addAll([
          // Audio upload or URL
          SizedBox(height: 16.h),
          _buildMediaUploader(
            title: 'Audio Source',
            useUpload: _useAudioUpload,
            toggleUpload: () {
              setState(() {
                _useAudioUpload = !_useAudioUpload;
                if (_useAudioUpload) _audioUrlController.clear();
                else _pickedAudio = null;
              });
            },
            pickMedia: _pickAudio,
            pickedMedia: _pickedAudio,
            urlController: _audioUrlController,
            uploadHintText: 'Tap to choose audio',
            mediaIcon: Icons.audiotrack,
          ),

          // Thumbnail (optional for audio)
          SizedBox(height: 16.h),
          _buildMediaUploader(
            title: 'Thumbnail (Optional)',
            useUpload: _useThumbnailUpload,
            toggleUpload: () {
              setState(() {
                _useThumbnailUpload = !_useThumbnailUpload;
                if (_useThumbnailUpload) _thumbnailUrlController.clear();
                else _pickedThumbnail = null;
              });
            },
            pickMedia: _pickThumbnail,
            pickedMedia: _pickedThumbnail,
            urlController: _thumbnailUrlController,
            uploadHintText: 'Tap to choose thumbnail',
            mediaIcon: Icons.image,
          ),

          // Media duration
          SizedBox(height: 16.h),
          FadeInUp(
            duration: const Duration(milliseconds: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media Duration',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _mediaDurationController,
                  decoration: InputDecoration(
                    hintText: 'Enter duration (e.g., 5:30)',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.w,
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Author name without icon
          SizedBox(height: 16.h),
          FadeInUp(
            duration: const Duration(milliseconds: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip Author',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _authorController,
                  decoration: InputDecoration(
                    hintText: AppStrings.tipsAuthorHint,
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.w,
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ]);
        break;

      case 'image':
        fields.addAll([
          // Image upload or URL
          SizedBox(height: 16.h),
          _buildMediaUploader(
            title: 'Image Source',
            useUpload: _useImageUpload,
            toggleUpload: () {
              setState(() {
                _useImageUpload = !_useImageUpload;
                if (_useImageUpload) _imageUrlController.clear();
                else _pickedImage = null;
              });
            },
            pickMedia: _pickImage,
            pickedMedia: _pickedImage,
            urlController: _imageUrlController,
            uploadHintText: 'Tap to choose image',
            mediaIcon: Icons.image,
          ),
        ]);
        break;

      case 'quote':
      case 'tip':
      case 'healthTips':
      default:
        fields.addAll([
          // Author fields
          SizedBox(height: 16.h),
          _buildAuthorFields(theme, isDark),
        ]);
        break;
    }

    // Common fields at the bottom for all types
    fields.addAll([
      // Category field
      SizedBox(height: 16.h),
      FadeInUp(
        duration: const Duration(milliseconds: 940),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
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
              hint: Text(
                AppStrings.categoryHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              items: _categoryCache.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value.categoryName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 1.w,
                  ),
                ),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),

      // Featured and Premium toggles
      SizedBox(height: 16.h),
      FadeInUp(
        duration: const Duration(milliseconds: 1020),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.w,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              'Featured',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            subtitle: Text(
              'Show in featured section',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            value: _isFeatured,
            onChanged: (value) {
              setState(() => _isFeatured = value);
            },
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.5),
          ),
        ),
      ),

      SizedBox(height: 8.h),

      FadeInUp(
        duration: const Duration(milliseconds: 1100),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.w,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              'Premium',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            subtitle: Text(
              'Available for premium users only',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            value: _isPremium,
            onChanged: (value) {
              setState(() => _isPremium = value);
            },
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.5),
            secondary: Icon(
              Icons.workspace_premium,
              color: _isPremium ? Colors.amber : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
        ),
      ),

      // Preferences section
      SizedBox(height: 16.h),
      FadeInUp(
        duration: const Duration(milliseconds: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: _buildPreferenceChips(),
            ),
          ],
        ),
      ),

      SizedBox(height: 80.h), // Extra space at the bottom
    ]);

    return Column(children: fields);
  }

  // Author name and icon fields
  Widget _buildAuthorFields(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Author name
        FadeInUp(
          duration: const Duration(milliseconds: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tip Author',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(
                  hintText: AppStrings.tipsAuthorHint,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.w,
                    ),
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),

        // Author icon
        SizedBox(height: 16.h),
        FadeInUp(
          duration: const Duration(milliseconds: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Author Icon',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
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
                GestureDetector(
                  onTap: _pickAuthorIcon,
                  child: DottedBorder(
                    color: AppColors.primary,
                    strokeWidth: 1.w,
                    dashPattern: const [8, 4],
                    borderType: BorderType.RRect,
                    radius: Radius.circular(12.r),
                    child: Container(
                      width: double.infinity,
                      height: _pickedAuthorIcon == null ? 120.h : 150.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                            AppColors.darkSurface,
                            AppColors.darkSurface.withOpacity(0.7),
                          ]
                              : [
                            AppColors.lightSurface,
                            Colors.grey.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? AppColors.shadow
                                : AppColors.shadow.withOpacity(0.08),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: _pickedAuthorIcon == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 40.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Tap to choose icon (PNG or JPEG)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
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
                )
              else
                TextField(
                  controller: _authorIconUrlController,
                  decoration: InputDecoration(
                    hintText: 'Enter icon URL (PNG or JPEG)',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.w,
                      ),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Builds preference chips
  List<Widget> _buildPreferenceChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _preferenceCache.entries.map((entry) {
      final pref = entry.value;
      final isSelected = _selectedPreferenceIds.contains(entry.key);
      return FadeInUp(
        duration: Duration(
          milliseconds: 300 + _preferenceCache.entries.toList().indexOf(entry) * 80,
        ),
        child: customSelectableChip(
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
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isDataLoaded) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
                    _tip == null
                        ? AppStrings.addTipTitle
                        : AppStrings.editTipTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22.sp,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20.sp,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _saveButtonController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _saveTip,
                        child: Container(
                          margin: EdgeInsets.only(right: 16.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? AppColors.shadow
                                    : AppColors.shadow.withOpacity(0.08),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.floppyDisk,
                                size: 14.sp,
                                color: AppColors.lightBackground,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Save',
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
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Tip Type Selection
                      FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              width: 1.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 8.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tip Type',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                hint: Text(
                                  AppStrings.tipsTypeHint,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                items: tipsTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type.capitalize(),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value;
                                    // Clear media fields when type changes
                                    _pickedVideo = null;
                                    _pickedAudio = null;
                                    _pickedImage = null;
                                    _pickedThumbnail = null;
                                    if (_tip == null) { // Only clear fields if adding new tip
                                      _videoUrlController.clear();
                                      _audioUrlController.clear();
                                      _imageUrlController.clear();
                                      _thumbnailUrlController.clear();
                                      _mediaDurationController.clear();
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.w,
                                    ),
                                  ),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down_circle,
                                  color: AppColors.primary,
                                ),
                                dropdownColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dynamic fields based on selected type
                      _buildTipFields(),
                    ]),
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
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 1260),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: _saveButtonController,
              curve: Curves.easeOut,
            ),
          ),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: _saveTip,
            label: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.shadow
                        : AppColors.shadow.withOpacity(0.15),
                    blurRadius: 8.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save,
                    color: AppColors.lightBackground,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _tip == null ? 'Save Tip' : 'Update Tip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.lightBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}