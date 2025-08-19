import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:io';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../subscription/presentation/providers/premium_status_provider.dart';

class ImageViewerScreen extends StatefulWidget {
  final TipModel tip;
  final List<TipModel> imageTips;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.tip,
    required this.imageTips,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> with SingleTickerProviderStateMixin {
  late CarouselSliderController _carouselController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;
  bool _isFavorite = false;
  bool _showControls = true;
  bool _isDownloading = false;
  bool _isFullScreen = false;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _carouselController = CarouselSliderController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _initializeFavorite();
    _fetchCategoryName();
  }

  void _initializeFavorite() {
    final userId = AuthService().getCurrentUser()?.uid ?? '';
    if (userId.isNotEmpty) {
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      favoritesProvider.loadFavorites(userId).then((_) {
        if (mounted) {
          setState(() {
            _isFavorite = favoritesProvider.isFavorite(
              widget.imageTips[_currentIndex].tipsId,
              userId,
            );
          });
        }
      });
    }
  }

  Future<void> _fetchCategoryName() async {
    final currentTip = widget.imageTips[_currentIndex];
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(currentTip.categoryId)
          .get();
      if (doc.exists && mounted) {
        final category = CategoryModel.fromFirestore(doc.data()!, doc.id);
        setState(() {
          _categoryName = category.categoryName;
        });
      } else {
        setState(() {
          _categoryName = 'Uncategorized';
        });
      }
    } catch (e) {
      log('Error fetching category: $e', name: 'ImageViewerScreen');
      if (mounted) {
        setState(() {
          _categoryName = 'Uncategorized';
        });
      }
    }
  }

  void _toggleFavorite() {
    final userId = AuthService().getCurrentUser()?.uid ?? '';
    if (userId.isNotEmpty) {
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

      HapticFeedback.lightImpact();

      if (_isFavorite) {
        final favorite = favoritesProvider.favorites.firstWhere(
              (f) => f.tipId == widget.imageTips[_currentIndex].tipsId && f.userId == userId,
          orElse: () => FavoriteModel(id: '', tipId: widget.imageTips[_currentIndex].tipsId, userId: userId),
        );
        favoritesProvider.deleteFavorite(favorite.id);
      } else {
        final favorite = FavoriteModel(
          id: '${userId}_${widget.imageTips[_currentIndex].tipsId}',
          tipId: widget.imageTips[_currentIndex].tipsId,
          userId: userId,
        );
        favoritesProvider.addFavorite(favorite);
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });
    } else {
      _showSnackBar('Please log in to add favorites', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  void _shareImage() async {
    final currentTip = widget.imageTips[_currentIndex];
    if (currentTip.imageUrl == null) {
      _showSnackBar('No image available to share', isError: true);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );

      final response = await http.get(Uri.parse(currentTip.imageUrl!));
      final bytes = response.bodyBytes;
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/image_${currentTip.tipsId}.jpg');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Check out this image!',
      );

      Future.delayed(const Duration(seconds: 5), () {
        file.delete().catchError((e) {
          log('Failed to delete shared file: $e', name: 'ImageViewerScreen');
        });
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Failed to share image', isError: true);
      log('Share error: $e', name: 'ImageViewerScreen');
    }
  }

  Future<void> _downloadImage() async {
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
    if (!canAccessPremium) {
      _showSnackBar('Subscription required to download', isError: true);
      return;
    }

    if (_isDownloading) return;

    final currentTip = widget.imageTips[_currentIndex];
    if (currentTip.imageUrl == null) {
      _showSnackBar('No image available to download', isError: true);
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        _showSnackBar('Photo permission denied', isError: true);
        setState(() => _isDownloading = false);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );

      final response = await http.get(Uri.parse(currentTip.imageUrl!)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Download timeout'),
      );
      final bytes = response.bodyBytes;

      Directory saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Pictures/Wellness');
      } else {
        saveDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Pictures/Wellness');
      }

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final file = File('${saveDir.path}/wellness_image_${currentTip.tipsId}.jpg');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context);

      _showSnackBar('Image downloaded to Pictures/Wellness', isError: false);
      log('Image downloaded to: ${file.path}', name: 'ImageViewerScreen');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Failed to download image', isError: true);
      log('Download error: $e', name: 'ImageViewerScreen');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _showControls = !_showControls;
      _isFullScreen = !_showControls; // Updated to sync with showControls
      if (_showControls) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTip = widget.imageTips[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _showControls
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // Center the title
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero, // remove default IconButton padding
            constraints: BoxConstraints(), // remove default size constraints
            icon: Container(
              padding: EdgeInsets.all(12.r), // size of background
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1, // border width
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ),


        title: Text(
          _categoryName ?? 'Loading...',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: _buildChipButton(
              label: '${_currentIndex + 1}/${widget.imageTips.length}',
            ),
          ),
        ],
      )
          : null,
      body: GestureDetector(
        onTap: _showControls ? null : _toggleFullScreen,
        child: CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.imageTips.length,
          itemBuilder: (context, index, realIndex) {
            final tip = widget.imageTips[index];
            final isCurrent = index == _currentIndex;

            return Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                image: tip.imageUrl != null
                    ? DecorationImage(
                  image: NetworkImage(tip.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image load error
                  },
                )
                    : null,
                color: tip.imageUrl == null ? Colors.grey.shade900 : null,
              ),
              child: tip.imageUrl == null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 48.sp,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No image available',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              )
                  : null,
            );
          },
          options: CarouselOptions(
            initialPage: _currentIndex,
            viewportFraction: 1.0,
            height: double.infinity,
            enableInfiniteScroll: false,
            scrollDirection: Axis.vertical,
            pageSnapping: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
                _initializeFavorite();
                _fetchCategoryName();
              });
            },
          ),
        ),
      ),
      bottomNavigationBar: _showControls
          ? Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              onPressed: _toggleFavorite,
              icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              isActive: _isFavorite,
              activeColor: Colors.red,
              label: 'Favorite',
            ),
            _buildActionButton(
              onPressed: _shareImage,
              icon: Icons.share_rounded,
              label: 'Share',
            ),
            _buildActionButton(
              onPressed: _isDownloading ? null : _downloadImage,
              icon: Icons.download_rounded,
              label: 'Download',
              isLoading: _isDownloading,
            ),
            _buildActionButton(
              onPressed: _toggleFullScreen,
              icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              label: _isFullScreen ? 'Exit' : 'Fullscreen',
              isActive: false,
            ),
          ],
        ),
      )
          : null,
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isActive = false,
    Color? activeColor,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                // Neutral styles only - no active background, border, or shadow changes
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: isLoading
                  ? SizedBox(
                width: 24.sp,
                height: 24.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              )
                  : Icon(
                icon,
                // Only apply active color to the icon when active
                color: isActive
                    ? (activeColor ?? AppColors.primary)
                    : Colors.white,
                size: 24.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7), // Removed active color for label
          ),
        ),
      ],
    );
  }

  Widget _buildChipButton({required String label}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleFullScreen,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Tooltip(
            message: _isFullScreen ? "Exit Fullscreen" : "Fullscreen",
            child: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }
}