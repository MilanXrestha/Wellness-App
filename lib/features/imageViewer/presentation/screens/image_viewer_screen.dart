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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../subscription/presentation/providers/premium_status_provider.dart';

class CustomCacheManager extends CacheManager {
  static const key = 'customImageCache';
  static final CustomCacheManager _instance = CustomCacheManager._();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._()
      : super(Config(
    key,
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
    fileService: HttpFileService(),
  ));
}

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
  bool _showControls = true;
  bool _isDownloading = false;
  bool _isFullScreen = false;
  String? _categoryName;
  final CustomCacheManager _cacheManager = CustomCacheManager();

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

    // Load favorites initially
    _loadFavorites();
    _fetchCategoryName();

    // Precache images for better performance
    _precacheImages();
  }

  void _precacheImages() {
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
    for (var tip in widget.imageTips) {
      if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty && (!tip.isPremium || canAccessPremium)) {
        _cacheManager.getSingleFile(tip.imageUrl!).catchError((e) {
          debugPrint('Error precaching image ${tip.imageUrl}: $e');
        });
      }
    }
  }

  void _loadFavorites() {
    final userId = AuthService().getCurrentUser()?.uid ?? '';
    if (userId.isNotEmpty) {
      // Load favorites but don't set state here, we'll use Consumer to react to changes
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites(userId);
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
    if (userId.isEmpty) {
      _showSnackBar('Please log in to add favorites', isError: true);
      return;
    }

    // Check for premium status if current tip is premium
    final isPremiumContent = widget.imageTips[_currentIndex].isPremium ?? false;
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;

    if (isPremiumContent && !canAccessPremium) {
      _showSnackBar('Subscription required to favorite premium content', isError: true);
      return;
    }

    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    final currentTipId = widget.imageTips[_currentIndex].tipsId;
    final isFavorite = favoritesProvider.isFavorite(currentTipId, userId);

    HapticFeedback.lightImpact();

    if (isFavorite) {
      final favorite = favoritesProvider.favorites.firstWhere(
            (f) => f.tipId == currentTipId && f.userId == userId,
        orElse: () => FavoriteModel(id: '', tipId: currentTipId, userId: userId),
      );
      favoritesProvider.deleteFavorite(favorite.id);
    } else {
      final favorite = FavoriteModel(
        id: '${userId}_$currentTipId',
        tipId: currentTipId,
        userId: userId,
      );
      favoritesProvider.addFavorite(favorite);
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

      // Try to get cached file first
      File file;
      try {
        file = await _cacheManager.getSingleFile(currentTip.imageUrl!);
      } catch (e) {
        // If cache fails, download directly
        final response = await http.get(Uri.parse(currentTip.imageUrl!));
        final bytes = response.bodyBytes;
        final directory = await getTemporaryDirectory();
        file = File('${directory.path}/image_${currentTip.tipsId}.jpg');
        await file.writeAsBytes(bytes);
      }

      if (mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Check out this image!',
      );

      // Don't delete cached files, keep them for future use
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Failed to share image', isError: true);
      log('Share error: $e', name: 'ImageViewerScreen');
    }
  }

  Future<void> _downloadImage() async {
    final isPremiumContent = widget.imageTips[_currentIndex].isPremium ?? false;
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;

    if (isPremiumContent && !canAccessPremium) {
      _showSnackBar('Subscription required to download premium content', isError: true);
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

      // Try to get cached file first
      File sourceFile;
      try {
        sourceFile = await _cacheManager.getSingleFile(currentTip.imageUrl!);
      } catch (e) {
        // If cache fails, download directly
        final response = await http.get(Uri.parse(currentTip.imageUrl!)).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Download timeout'),
        );
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        sourceFile = File('${tempDir.path}/temp_image_${currentTip.tipsId}.jpg');
        await sourceFile.writeAsBytes(bytes);
      }

      Directory saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Pictures/Wellness');
      } else {
        saveDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Pictures/Wellness');
      }

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final destFile = File('${saveDir.path}/wellness_image_${currentTip.tipsId}.jpg');
      await sourceFile.copy(destFile.path);

      if (mounted) Navigator.pop(context);

      _showSnackBar('Image downloaded to Pictures/Wellness', isError: false);
      log('Image downloaded to: ${destFile.path}', name: 'ImageViewerScreen');
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
      _isFullScreen = !_showControls;
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
    final userId = AuthService().getCurrentUser()?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _showControls ? null : _toggleFullScreen,
            child: CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: widget.imageTips.length,
              itemBuilder: (context, index, realIndex) {
                final tip = widget.imageTips[index];

                return tip.imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: tip.imageUrl!,
                  cacheManager: _cacheManager,
                  imageBuilder: (context, imageProvider) => Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.w,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade900,
                    child: Center(
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
                            'Failed to load image',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : Container(
                  color: Colors.grey.shade900,
                  child: Center(
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
                  ),
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
                    _fetchCategoryName();
                  });
                },
              ),
            ),
          ),
          if (_showControls)
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: 50.h,
                  color: Colors.transparent, // Matches Scaffold background
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        padding: EdgeInsets.all(8.r),
                        constraints: BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          _categoryName ?? 'Loading...',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _buildChipButton(
                        label: '${_currentIndex + 1}/${widget.imageTips.length}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  padding: EdgeInsets.only(bottom: 30.h, top: 20.h),
                  child: Consumer2<FavoritesProvider, PremiumStatusProvider>(
                    builder: (context, favoritesProvider, premiumProvider, _) {
                      final currentTipId = widget.imageTips[_currentIndex].tipsId;
                      final isFavorite = favoritesProvider.isFavorite(currentTipId, userId);
                      final isPremiumContent = widget.imageTips[_currentIndex].isPremium ?? false;
                      final canAccessPremium = premiumProvider.canAccessPremium;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            onPressed: _toggleFavorite,
                            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            isActive: isFavorite,
                            activeColor: Colors.red,
                            label: 'Favorite',
                            isPremium: isPremiumContent && !canAccessPremium,
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
                            isPremium: isPremiumContent && !canAccessPremium,
                          ),
                          _buildActionButton(
                            onPressed: _toggleFullScreen,
                            icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            label: _isFullScreen ? 'Exit' : 'Fullscreen',
                            isActive: false,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isActive = false,
    Color? activeColor,
    bool isLoading = false,
    bool isPremium = false,
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 24.sp,
                      height: 24.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: isActive
                          ? (activeColor ?? AppColors.primary)
                          : Colors.white,
                      size: 24.sp,
                    ),
                  if (isPremium)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Icon(
                        Icons.lock,
                        color: Colors.amber,
                        size: 14.sp,
                      ),
                    ),
                ],
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
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildChipButton({required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
    );
  }
}