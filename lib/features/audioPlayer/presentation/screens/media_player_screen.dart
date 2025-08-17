import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer';
import 'dart:ui';
import 'dart:math' as math;

import '../../../favorites/data/models/favorite_model.dart' show FavoriteModel;
import '../../../subscription/presentation/providers/premium_status_provider.dart';
import '../widgets/playlist_bottom_sheet.dart';

class MediaPlayerScreen extends StatefulWidget {
  final TipModel tip;
  final String categoryName;
  final List<TipModel> featuredTips;

  const MediaPlayerScreen({
    super.key,
    required this.tip,
    required this.categoryName,
    required this.featuredTips,
  });

  @override
  MediaPlayerScreenState createState() => MediaPlayerScreenState();
}

class MediaPlayerScreenState extends State<MediaPlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _shakeController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _heartController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _heartAnimation;
  Duration? _duration;
  Duration? _position;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  String? _userId;
  late ValueNotifier<int> _currentTrackIndex; // Changed to ValueNotifier

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentTrackIndex = ValueNotifier<int>(
      widget.featuredTips.indexWhere((t) => t.tipsId == widget.tip.tipsId),
    ); // Initialize ValueNotifier

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -0.05), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.05, end: 0.05),
        weight: 50,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 0), weight: 25),
    ]).animate(_shakeController);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.bounceOut),
    );

    _initializeAudio();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final authService = AuthService();
    final user = authService.getCurrentUser();
    if (user != null) {
      _userId = user.uid;
      log('Authenticated user found: $_userId', name: 'MediaPlayerScreen');
      await Provider.of<FavoritesProvider>(
        context,
        listen: false,
      ).loadFavorites(_userId!);
    } else {
      log('No authenticated user found', name: 'MediaPlayerScreen');
    }
  }

  Future<void> _initializeAudio() async {
    try {
      if (widget.featuredTips[_currentTrackIndex.value].audioUrl != null &&
          widget.featuredTips[_currentTrackIndex.value].audioUrl!.isNotEmpty) {
        await _audioPlayer.setUrl(
          widget.featuredTips[_currentTrackIndex.value].audioUrl!,
        );
        setState(() {
          _isLoading = false;
        });

        _audioPlayer.durationStream.listen((duration) {
          setState(() {
            _duration = duration;
          });
        });

        _audioPlayer.positionStream.listen((position) {
          setState(() {
            _position = position;
          });
        });

        _audioPlayer.playerStateStream.listen((state) {
          setState(() {
            _isPlaying = state.playing;
          });

          if (state.playing) {
            _rotationController.repeat();
            _pulseController.repeat(reverse: true);
          } else {
            _rotationController.stop();
            _pulseController.stop();
          }

          if (state.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
            _playNextTrack();
          }
        });

        log(
          'Audio initialized for ${widget.featuredTips[_currentTrackIndex.value].tipsTitle}',
          name: 'MediaPlayerScreen',
        );
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = AppLocalizations.of(context)!.errorLoadingAudio;
        });
        log(
          'No audio URL provided for ${widget.featuredTips[_currentTrackIndex.value].tipsTitle}',
          name: 'MediaPlayerScreen',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e is MissingPluginException
            ? 'Audio plugin not initialized. Please restart the app.'
            : AppLocalizations.of(context)!.errorLoadingAudio;
      });
      log('Error initializing audio: $e', name: 'MediaPlayerScreen');
    }
  }

  Future<void> _playNextTrack() async {
    if (_currentTrackIndex.value < widget.featuredTips.length - 1) {
      setState(() {
        _currentTrackIndex.value++; // Update ValueNotifier
        _isLoading = true;
      });
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(
        widget.featuredTips[_currentTrackIndex.value].audioUrl!,
      );
      setState(() {
        _isLoading = false;
      });
      final canAccessPremium = Provider.of<PremiumStatusProvider>(
        context,
        listen: false,
      ).canAccessPremium;
      if (widget.featuredTips[_currentTrackIndex.value].isPremium &&
          !canAccessPremium) {
        _shakeController.repeat();
      } else {
        _shakeController.stop();
        if (!_isPlaying) {
          await _audioPlayer.play();
        }
      }
    }
  }

  Future<void> _playPreviousTrack() async {
    if (_currentTrackIndex.value > 0) {
      setState(() {
        _currentTrackIndex.value--; // Update ValueNotifier
        _isLoading = true;
      });
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(
        widget.featuredTips[_currentTrackIndex.value].audioUrl!,
      );
      setState(() {
        _isLoading = false;
      });
      final canAccessPremium = Provider.of<PremiumStatusProvider>(
        context,
        listen: false,
      ).canAccessPremium;
      if (widget.featuredTips[_currentTrackIndex.value].isPremium &&
          !canAccessPremium) {
        _shakeController.repeat();
      } else {
        _shakeController.stop();
        if (!_isPlaying) {
          await _audioPlayer.play();
        }
      }
    }
  }

  void _shareTrack() {
    final trackUrl = widget.featuredTips[_currentTrackIndex.value].audioUrl ?? '';
    final trackTitle = widget.featuredTips[_currentTrackIndex.value].tipsTitle;
    Share.share(
      'Check out this track: $trackTitle\n$trackUrl',
      subject: 'Share $trackTitle',
    );
  }

  void _checkPremiumAccess(BuildContext context) {
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
      listen: false,
    ).canAccessPremium;
    if (widget.featuredTips[_currentTrackIndex.value].isPremium &&
        !canAccessPremium) {
      _showPremiumDialog(context);
      _audioPlayer.pause();
    } else {
      if (_isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play();
      }
    }
  }

  void _showPremiumDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20.r,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/svg/ic_crown.svg',
                    width: 56.r,
                    height: 56.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context)!.premiumContent,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppLocalizations.of(context)!.unlockPremiumBenefits,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16.sp,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        _buildBenefitRow(
                          context,
                          Icons.check_circle,
                          AppLocalizations.of(context)!.premiumAudioAccess,
                          isDarkMode,
                        ),
                        SizedBox(height: 8.h),
                        _buildBenefitRow(
                          context,
                          Icons.star_rounded,
                          AppLocalizations.of(context)!.exclusiveContent,
                          isDarkMode,
                        ),
                        SizedBox(height: 8.h),
                        _buildBenefitRow(
                          context,
                          Icons.download_rounded,
                          AppLocalizations.of(context)!.offlineAccess,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: BorderSide(
                                color: isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                width: 1.w,
                              ),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(
                              context,
                              RoutesName.subscriptionScreen,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.subscribeNow,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.white,
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
        );
      },
    );
  }

  Widget _buildBenefitRow(
      BuildContext context, IconData icon, String text, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppColors.primary,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14.sp,
              fontFamily: 'Poppins',
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(FavoritesProvider provider) async {
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
      listen: false,
    ).canAccessPremium;
    if (widget.featuredTips[_currentTrackIndex.value].isPremium && !canAccessPremium) {
      _showPremiumDialog(context);
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseLogIn),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final isFavorite = provider.favorites.any(
          (f) => f.tipId == widget.featuredTips[_currentTrackIndex.value].tipsId,
    );
    try {
      if (isFavorite) {
        final favorite = provider.favorites.firstWhere(
              (f) => f.tipId == widget.featuredTips[_currentTrackIndex.value].tipsId,
        );
        await provider.deleteFavorite(favorite.id);
      } else {
        final favorite = FavoriteModel(
          id: '${_userId}_${widget.featuredTips[_currentTrackIndex.value].tipsId}',
          userId: _userId!,
          tipId: widget.featuredTips[_currentTrackIndex.value].tipsId,
          createdAt: DateTime.now(),
        );
        await provider.addFavorite(favorite);
      }
      _heartController.forward().then((_) => _heartController.reverse());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildAlbumArt(bool isDarkMode) {
    return Container(
      width: 280.w,
      height: 280.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20.r,
            spreadRadius: 5.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  width: 3.w,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.primary.withOpacity(0.1),
                  ],
                ),
              ),
              child: ClipOval(
                child: widget.featuredTips[_currentTrackIndex.value].thumbnailUrl !=
                    null &&
                    widget.featuredTips[_currentTrackIndex.value].thumbnailUrl!
                        .isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl:
                  widget.featuredTips[_currentTrackIndex.value].thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.lightBackground,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.lightBackground,
                    child: Icon(
                      Icons.music_note_rounded,
                      color: AppColors.primary,
                      size: 80.sp,
                    ),
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    size: 80.sp,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaybackControls(bool isDarkMode) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = favoritesProvider.favorites.any(
              (f) => f.tipId == widget.featuredTips[_currentTrackIndex.value].tipsId,
        );

        return Column(
          children: [
            // Custom Slider
            CustomAudioSlider(
              duration: _duration,
              position: _position,
              onChanged: (value) {
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 24.h),
            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Playlist Button
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/svg/ic_playlist.svg',
                    width: 28.sp,
                    height: 28.sp,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlaylistBottomSheet(
                        featuredTips: widget.featuredTips,
                        categoryName: widget.categoryName,
                        currentTrackIndex: _currentTrackIndex, // Pass ValueNotifier
                        onTrackSelected: (index) async {
                          if (index != _currentTrackIndex.value) {
                            setState(() {
                              _currentTrackIndex.value = index; // Update ValueNotifier
                              _isLoading = true;
                            });
                            await _audioPlayer.stop();
                            await _audioPlayer.setUrl(
                              widget.featuredTips[_currentTrackIndex.value].audioUrl!,
                            );
                            setState(() {
                              _isLoading = false;
                            });
                            final canAccessPremium = Provider.of<PremiumStatusProvider>(
                              context,
                              listen: false,
                            ).canAccessPremium;
                            if (widget.featuredTips[_currentTrackIndex.value].isPremium &&
                                !canAccessPremium) {
                              _showPremiumDialog(context);
                              _shakeController.repeat();
                            } else {
                              _shakeController.stop();
                              await _audioPlayer.play();
                            }
                          }
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
                SizedBox(width: 8.w),
                // Previous Track
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/svg/ic_previous.svg',
                    width: 32.sp,
                    height: 32.sp,
                    color: _currentTrackIndex.value > 0
                        ? (isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                        : (isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)
                        .withOpacity(0.5),
                  ),
                  onPressed: _currentTrackIndex.value > 0 ? _playPreviousTrack : null,
                ),
                SizedBox(width: 16.w),
                // Play/Pause Button
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isPlaying ? 1.0 : _pulseAnimation.value,
                      child: Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 16.r,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 36.sp,
                            color: Colors.white,
                          ),
                          onPressed: () => _checkPremiumAccess(context),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 16.w),
                // Next Track
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/svg/ic_next.svg',
                    width: 32.sp,
                    height: 32.sp,
                    color: _currentTrackIndex.value < widget.featuredTips.length - 1
                        ? (isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                        : (isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)
                        .withOpacity(0.5),
                  ),
                  onPressed: _currentTrackIndex.value < widget.featuredTips.length - 1
                      ? _playNextTrack
                      : null,
                ),
                SizedBox(width: 8.w),
                // Favorite Button
                AnimatedBuilder(
                  animation: _heartAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _heartAnimation.value,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? Colors.green
                              : (isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                          size: 28.sp,
                        ),
                        onPressed: () => _toggleFavorite(favoritesProvider),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Wave Animation (only shown when playing)
            if (_isPlaying)
              WaveAnimation(isPlaying: _isPlaying, color: AppColors.primary),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
    ).canAccessPremium;
    if (widget.featuredTips[_currentTrackIndex.value].isPremium &&
        !canAccessPremium) {
      _shakeController.repeat();
    } else {
      _shakeController.stop();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _shakeController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _heartController.dispose();
    _currentTrackIndex.dispose(); // Dispose ValueNotifier
    super.dispose();
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
      listen: false,
    ).canAccessPremium;

    return Consumer2<PremiumStatusProvider, FavoritesProvider>(
      builder: (context, premiumStatus, favoritesProvider, child) {
        return Scaffold(
          backgroundColor: isDarkMode
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [AppColors.darkSurface, AppColors.darkBackground]
                    : [AppColors.lightBackground, AppColors.lightSurface],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  children: [
                    // Header with back icon, category name, and share icon
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 20.sp,
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.darkTextPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.categoryName,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 18.sp,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppColors.darkTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/svg/ic_share.svg',
                            width: 20.sp,
                            height: 20.sp,
                            color: isDarkMode
                                ? Colors.white
                                : AppColors.darkTextPrimary,
                          ),
                          onPressed: _shareTrack,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // Album Art
                    _buildAlbumArt(isDarkMode),
                    SizedBox(height: 32.h),
                    // Title and Artist with Crown Icon for Premium
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.featuredTips[_currentTrackIndex.value].tipsTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22.sp,
                                  color: isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (widget.featuredTips[_currentTrackIndex.value].isPremium &&
                                !canAccessPremium)
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: SvgPicture.asset(
                                  'assets/icons/svg/ic_crown.svg',
                                  width: 20.sp,
                                  height: 20.sp,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          widget.featuredTips[_currentTrackIndex.value].tipsAuthor,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Poppins',
                            fontSize: 15.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    // Loading, Error, or Playback Controls
                    if (_isLoading)
                      Container(
                        height: 120.h,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3.w,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_hasError)
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 40.sp,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              _errorMessage ??
                                  AppLocalizations.of(context)!.errorLoadingAudio,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 13.sp,
                                color: AppColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _initializeAudio,
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 10.h,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.retry,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildPlaybackControls(isDarkMode),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// WaveAnimation widget
class WaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const WaveAnimation({Key? key, required this.isPlaying, required this.color})
      : super(key: key);

  @override
  _WaveAnimationState createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
          (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (index * 100)),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(WaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              width: 4.w,
              height: 20.h * _animations[index].value,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          },
        );
      }),
    );
  }
}

// CustomAudioSlider widget
class CustomAudioSlider extends StatelessWidget {
  final Duration? duration;
  final Duration? position;
  final ValueChanged<double>? onChanged;
  final bool isDarkMode;

  const CustomAudioSlider({
    Key? key,
    this.duration,
    this.position,
    this.onChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WaveformPainter(
                progress: (position?.inMilliseconds ?? 0) /
                    (duration?.inMilliseconds ?? 1),
                waveColor: AppColors.primary.withOpacity(0.1),
                progressColor: AppColors.primary.withOpacity(0.3),
              ),
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              thumbColor: AppColors.primary,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
              trackHeight: 4.h,
              overlayColor: AppColors.primary.withOpacity(0.2),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
            ),
            child: Slider(
              value: position?.inSeconds.toDouble() ?? 0,
              max: duration?.inSeconds.toDouble() ?? 1,
              onChanged: onChanged,
            ),
          ),
          // Time labels
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(
              _formatDuration(position),
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// WaveformPainter
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color waveColor;
  final Color progressColor;

  WaveformPainter({
    required this.progress,
    required this.waveColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final waveWidth = 3.w;
    final waveSpacing = 2.w;
    final totalWidth = waveWidth + waveSpacing;
    final waveCount = (size.width / totalWidth).floor();

    for (int i = 0; i < waveCount; i++) {
      final x = i * totalWidth + waveWidth / 2;
      final waveHeight = (20 + (i % 3) * 10).h;
      final y = size.height / 2;

      if (x / size.width <= progress) {
        paint.color = progressColor;
      } else {
        paint.color = waveColor;
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: waveWidth,
            height: waveHeight,
          ),
          Radius.circular(waveWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}