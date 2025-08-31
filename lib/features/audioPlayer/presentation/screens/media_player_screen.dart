import 'dart:developer';
import 'dart:ui';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart' show FavoriteModel;
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
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

class MediaPlayerScreenState extends State<MediaPlayerScreen> with TickerProviderStateMixin {
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
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isPlaying = false;
  String? _userId;
  late ValueNotifier<int> _currentTrackIndex;
  final _subscriptions = CompositeSubscription();
  late DefaultCacheManager _cacheManager;
  double _downloadProgress = 0.0; // Track download progress
  bool _isConnected = true; // Cache connectivity status
  Map<String, bool> _cachedAudioFiles = {}; // Track which files are cached

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _cacheManager = DefaultCacheManager();

    // Safety check: if featuredTips is empty, add the current tip
    if (widget.featuredTips.isEmpty) {
      log('Warning: featuredTips was empty, adding current tip', name: 'MediaPlayerScreen');
      widget.featuredTips.add(widget.tip);
    }

    // Find the current tip in the featuredTips list, default to 0 if not found
    int initialIndex = widget.featuredTips.indexWhere((t) => t.tipsId == widget.tip.tipsId);
    if (initialIndex < 0) {
      initialIndex = 0;
      log('Warning: current tip not found in featuredTips, defaulting to index 0', name: 'MediaPlayerScreen');
    }

    _currentTrackIndex = ValueNotifier<int>(initialIndex);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -0.05), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -0.05, end: 0.05), weight: 50),
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

    _initializeUser();
    _checkConnectivity();
    _setupAudioStreams(); // Setup streams first
    _initializeAudio(); // Then initialize audio
    _precacheNextTrack(); // Pre-cache the next track
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Setup audio streams for position and state updates
  void _setupAudioStreams() {
    _subscriptions.add(
      _audioPlayer.durationStream.listen((duration) {
        _safeSetState(() {
          _duration = duration;
        });
      }),
    );

    _subscriptions.add(
      _audioPlayer.positionStream.listen((position) {
        _safeSetState(() {
          _position = position;
        });
      }),
    );

    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((state) {
        _safeSetState(() {
          _isPlaying = state.playing;

          // If we're playing, we're definitely not initializing anymore
          if (state.playing) {
            _isInitializing = false;
          }
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

        // If we were loading and now we're ready, we're not loading anymore
        if (state.processingState == ProcessingState.ready && _isLoading) {
          _safeSetState(() {
            _isLoading = false;
            _isInitializing = false;
          });
        }
      }),
    );
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _safeSetState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
    log('Connectivity status: $_isConnected', name: 'MediaPlayerScreen');
  }

  Future<void> _initializeUser() async {
    final authService = AuthService();
    final user = authService.getCurrentUser();
    if (user != null) {
      _userId = user.uid;
      log('Authenticated user found: $_userId', name: 'MediaPlayerScreen');
      await Provider.of<FavoritesProvider>(context, listen: false).loadFavorites(_userId!);
    } else {
      log('No authenticated user found', name: 'MediaPlayerScreen');
    }
  }

  Future<void> _initializeAudio() async {
    try {
      // Safety check to prevent index out of bounds
      if (_currentTrackIndex.value >= widget.featuredTips.length) {
        log('Warning: _currentTrackIndex out of bounds, resetting to 0', name: 'MediaPlayerScreen');
        _currentTrackIndex.value = 0;
      }

      final currentTip = widget.featuredTips[_currentTrackIndex.value];

      if (currentTip.audioUrl == null || currentTip.audioUrl!.isEmpty) {
        _safeSetState(() {
          _isLoading = false;
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'No audio URL provided';
        });
        log('No audio URL provided for ${currentTip.tipsTitle}', name: 'MediaPlayerScreen');
        return;
      }

      // Check if we already know this file is cached
      if (_cachedAudioFiles[currentTip.audioUrl!] == true) {
        final fileInfo = await _cacheManager.getFileFromCache(currentTip.audioUrl!);
        if (fileInfo != null && fileInfo.file.existsSync()) {
          await _audioPlayer.setFilePath(fileInfo.file.path);
          log('Playing from cached file (fast path): ${fileInfo.file.path}', name: 'MediaPlayerScreen');
          _safeSetState(() {
            _isLoading = false;
            _isInitializing = false;
            _downloadProgress = 1.0;
          });
          return;
        }
      }

      // Check if the file is cached
      final fileInfo = await _cacheManager.getFileFromCache(currentTip.audioUrl!);

      if (fileInfo != null && fileInfo.file.existsSync()) {
        // Use cached file
        await _audioPlayer.setFilePath(fileInfo.file.path);
        log('Playing from cached file: ${fileInfo.file.path}', name: 'MediaPlayerScreen');
        _cachedAudioFiles[currentTip.audioUrl!] = true;
        _safeSetState(() {
          _isLoading = false;
          _isInitializing = false;
          _downloadProgress = 1.0;
        });
      } else if (_isConnected) {
        // Download with progress tracking
        _safeSetState(() {
          _isLoading = true;
          _downloadProgress = 0.0;
        });

        try {
          final stream = _cacheManager.getFileStream(currentTip.audioUrl!, withProgress: true);
          await for (final result in stream) {
            if (result is DownloadProgress) {
              _safeSetState(() {
                _downloadProgress = result.progress ?? 0.0;
              });
              log('Download progress: ${_downloadProgress * 100}%', name: 'MediaPlayerScreen');
            } else if (result is FileInfo) {
              _cachedAudioFiles[currentTip.audioUrl!] = true;
              await _audioPlayer.setFilePath(result.file.path);
              log('Downloaded and cached file: ${result.file.path}', name: 'MediaPlayerScreen');
              _safeSetState(() {
                _isLoading = false;
                _isInitializing = false;
                _downloadProgress = 1.0;
              });
              break;
            }
          }
        } catch (e) {
          log('Error during file download: $e', name: 'MediaPlayerScreen');
          _safeSetState(() {
            _isLoading = false;
            _isInitializing = false;
            _hasError = true;
            _errorMessage = 'Failed to download audio file';
          });
        }
      } else {
        // Offline and no cached file
        _safeSetState(() {
          _isLoading = false;
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'No internet connection and audio not cached';
        });
        log('Offline and no cached file for ${currentTip.tipsTitle}', name: 'MediaPlayerScreen');
      }

      log('Audio initialized for ${currentTip.tipsTitle}', name: 'MediaPlayerScreen');
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _isInitializing = false;
        _hasError = true;
        _errorMessage = e is MissingPluginException
            ? 'Audio plugin not initialized. Please restart the app.'
            : 'Error loading audio: ${e.toString()}';
      });
      log('Error initializing audio: $e', name: 'MediaPlayerScreen');
    }
  }

  Future<void> _precacheNextTrack() async {
    if (_currentTrackIndex.value + 1 < widget.featuredTips.length) {
      final nextTip = widget.featuredTips[_currentTrackIndex.value + 1];
      if (nextTip.audioUrl != null && nextTip.audioUrl!.isNotEmpty && _isConnected) {
        // Check if we already know this file is cached
        if (_cachedAudioFiles[nextTip.audioUrl!] == true) {
          return; // Already cached, no need to check again
        }

        final fileInfo = await _cacheManager.getFileFromCache(nextTip.audioUrl!);
        if (fileInfo != null && fileInfo.file.existsSync()) {
          _cachedAudioFiles[nextTip.audioUrl!] = true;
          log('Next track already cached: ${nextTip.tipsTitle}', name: 'MediaPlayerScreen');
        } else {
          log('Precaching next track: ${nextTip.tipsTitle}', name: 'MediaPlayerScreen');
          _cacheManager.downloadFile(nextTip.audioUrl!).then((_) {
            _cachedAudioFiles[nextTip.audioUrl!] = true;
            log('Next track cached successfully: ${nextTip.tipsTitle}', name: 'MediaPlayerScreen');
          }).catchError((e) {
            log('Failed to cache next track: $e', name: 'MediaPlayerScreen');
          });
        }
      }
    }
  }

  Future<void> _playNextTrack() async {
    if (_currentTrackIndex.value < widget.featuredTips.length - 1) {
      _safeSetState(() {
        _currentTrackIndex.value++;
        _isLoading = true;
        _isInitializing = true;
        _downloadProgress = 0.0;
        _hasError = false;
      });
      await _audioPlayer.stop();
      await _initializeAudio();
      final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
      if (widget.featuredTips[_currentTrackIndex.value].isPremium && !canAccessPremium) {
        _shakeController.repeat();
      } else {
        _shakeController.stop();
        if (!_hasError) {
          await _audioPlayer.play();
        }
      }
      _precacheNextTrack(); // Pre-cache the next track
    }
  }

  Future<void> _playPreviousTrack() async {
    if (_currentTrackIndex.value > 0) {
      _safeSetState(() {
        _currentTrackIndex.value--;
        _isLoading = true;
        _isInitializing = true;
        _downloadProgress = 0.0;
        _hasError = false;
      });
      await _audioPlayer.stop();
      await _initializeAudio();
      final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
      if (widget.featuredTips[_currentTrackIndex.value].isPremium && !canAccessPremium) {
        _shakeController.repeat();
      } else {
        _shakeController.stop();
        if (!_hasError) {
          await _audioPlayer.play();
        }
      }
      _precacheNextTrack(); // Pre-cache the next track
    }
  }

  void _shareTrack() {
    if (_currentTrackIndex.value >= 0 && _currentTrackIndex.value < widget.featuredTips.length) {
      final trackUrl = widget.featuredTips[_currentTrackIndex.value].audioUrl ?? '';
      final trackTitle = widget.featuredTips[_currentTrackIndex.value].tipsTitle;
      Share.share(
        'Check out this track: $trackTitle\n$trackUrl',
        subject: 'Share $trackTitle',
      );
    }
  }

  void _checkPremiumAccess(BuildContext context) {
    if (_currentTrackIndex.value < 0 || _currentTrackIndex.value >= widget.featuredTips.length) {
      log('Invalid track index: ${_currentTrackIndex.value}', name: 'MediaPlayerScreen');
      return;
    }

    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
    if (widget.featuredTips[_currentTrackIndex.value].isPremium && !canAccessPremium) {
      _showPremiumDialog(context);
      _audioPlayer.pause();
    } else {
      if (_isPlaying) {
        _audioPlayer.pause();
      } else {
        if (_hasError) {
          // Try to reinitialize if there was an error
          _safeSetState(() {
            _hasError = false;
            _isLoading = true;
          });
          _initializeAudio().then((_) {
            if (!_hasError) {
              _audioPlayer.play();
            }
          });
        } else {
          _audioPlayer.play();
        }
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
                color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
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
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppLocalizations.of(context)!.unlockPremiumBenefits,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16.sp,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(context, RoutesName.subscriptionScreen);
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

  Widget _buildBenefitRow(BuildContext context, IconData icon, String text, bool isDarkMode) {
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
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(FavoritesProvider provider) async {
    if (_currentTrackIndex.value < 0 || _currentTrackIndex.value >= widget.featuredTips.length) {
      log('Invalid track index for favorites: ${_currentTrackIndex.value}', name: 'MediaPlayerScreen');
      return;
    }

    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
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
    if (_currentTrackIndex.value < 0 || _currentTrackIndex.value >= widget.featuredTips.length) {
      log('Invalid track index for album art: ${_currentTrackIndex.value}', name: 'MediaPlayerScreen');
      return Container();
    }

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
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                    child: widget.featuredTips[_currentTrackIndex.value].thumbnailUrl != null &&
                        widget.featuredTips[_currentTrackIndex.value].thumbnailUrl!.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: widget.featuredTips[_currentTrackIndex.value].thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: 280.w,
                      height: 280.w,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
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
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        size: 80.sp,
                      ),
                    ),
                  ),
                ),
                // Loading overlay only when loading
                if (_isLoading)
                  Positioned.fill(
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 3.w,
                                  color: Colors.white,
                                  value: _downloadProgress > 0 ? _downloadProgress : null,
                                ),
                                if (_downloadProgress > 0) ...[
                                  SizedBox(height: 8.h),
                                  Text(
                                    '${(_downloadProgress * 100).toInt()}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaybackControls(bool isDarkMode) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        bool isFavorite = false;
        if (_currentTrackIndex.value >= 0 && _currentTrackIndex.value < widget.featuredTips.length) {
          isFavorite = favoritesProvider.favorites.any(
                (f) => f.tipId == widget.featuredTips[_currentTrackIndex.value].tipsId,
          );
        }

        return Column(
          children: [
            CustomAudioSlider(
              duration: _duration ?? Duration.zero,
              position: _position ?? Duration.zero,
              onChanged: (_hasError || _isInitializing) ? null : (value) {
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
              isDarkMode: isDarkMode,
              isActive: !_hasError && !_isInitializing,
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/svg/ic_playlist.svg',
                    width: 28.sp,
                    height: 28.sp,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  onPressed: _hasError ? null : () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlaylistBottomSheet(
                        featuredTips: widget.featuredTips,
                        categoryName: widget.categoryName,
                        currentTrackIndex: _currentTrackIndex,
                        onTrackSelected: (index) async {
                          if (index != _currentTrackIndex.value) {
                            _safeSetState(() {
                              _currentTrackIndex.value = index;
                              _isLoading = true;
                              _isInitializing = true;
                              _downloadProgress = 0.0;
                              _hasError = false;
                            });
                            await _audioPlayer.stop();
                            await _initializeAudio();
                            final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
                            if (widget.featuredTips[_currentTrackIndex.value].isPremium && !canAccessPremium) {
                              _showPremiumDialog(context);
                              _shakeController.repeat();
                            } else {
                              _shakeController.stop();
                              if (!_hasError) {
                                await _audioPlayer.play();
                              }
                            }
                            _precacheNextTrack();
                          }
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/svg/ic_previous.svg',
                    width: 32.sp,
                    height: 32.sp,
                    color: (_currentTrackIndex.value > 0 && !_hasError && !_isLoading)
                        ? (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.5),
                  ),
                  onPressed: (_currentTrackIndex.value > 0 && !_hasError && !_isLoading) ? _playPreviousTrack : null,
                ),
                SizedBox(width: 16.w),
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
                              _hasError ? Colors.grey : AppColors.primary,
                              _hasError ? Colors.grey.withOpacity(0.8) : AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_hasError ? Colors.grey : AppColors.primary).withOpacity(0.4),
                              blurRadius: 16.r,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _hasError ? Icons.refresh : (_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            size: 36.sp,
                            color: Colors.white,
                          ),
                          onPressed: _hasError
                              ? () {
                            _safeSetState(() {
                              _hasError = false;
                              _isLoading = true;
                            });
                            _initializeAudio().then((_) {
                              if (!_hasError) {
                                _audioPlayer.play();
                              }
                            });
                          }
                              : () => _checkPremiumAccess(context),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 16.w),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/svg/ic_next.svg',
                    width: 32.sp,
                    height: 32.sp,
                    color: (_currentTrackIndex.value < widget.featuredTips.length - 1 && !_hasError && !_isLoading)
                        ? (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                        : (isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.5),
                  ),
                  onPressed: (_currentTrackIndex.value < widget.featuredTips.length - 1 && !_hasError && !_isLoading) ? _playNextTrack : null,
                ),
                SizedBox(width: 8.w),
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
                              : (isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
    if (widget.featuredTips.isEmpty || _currentTrackIndex.value < 0 || _currentTrackIndex.value >= widget.featuredTips.length) {
      log('Error: Invalid featuredTips or index in didChangeDependencies', name: 'MediaPlayerScreen');
      return;
    }

    final canAccessPremium = Provider.of<PremiumStatusProvider>(context).canAccessPremium;
    if (widget.featuredTips[_currentTrackIndex.value].isPremium && !canAccessPremium) {
      _shakeController.repeat();
    } else {
      _shakeController.stop();
    }
  }

  @override
  void dispose() {
    log('Disposing MediaPlayerScreenState', name: 'MediaPlayerScreen');
    _audioPlayer.pause();
    _subscriptions.clear();
    log('Stream subscriptions canceled', name: 'MediaPlayerScreen');
    _audioPlayer.dispose();
    log('AudioPlayer disposed', name: 'MediaPlayerScreen');
    _shakeController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _heartController.dispose();
    _currentTrackIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (widget.featuredTips.isEmpty) {
      widget.featuredTips.add(widget.tip);
      log('Added current tip to empty featuredTips in build method', name: 'MediaPlayerScreen');
      _currentTrackIndex.value = 0;
    }

    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;

    return Consumer2<PremiumStatusProvider, FavoritesProvider>(
      builder: (context, premiumStatus, favoritesProvider, child) {
        return Scaffold(
          backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
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
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 20.sp,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.categoryName,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontFamily: 'Poppins',
                                fontSize: 18.sp,
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          onPressed: _shareTrack,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _buildAlbumArt(isDarkMode),
                    SizedBox(height: 32.h),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _currentTrackIndex.value >= 0 && _currentTrackIndex.value < widget.featuredTips.length
                                    ? widget.featuredTips[_currentTrackIndex.value].tipsTitle
                                    : "Audio Track",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22.sp,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_currentTrackIndex.value >= 0 &&
                                _currentTrackIndex.value < widget.featuredTips.length &&
                                widget.featuredTips[_currentTrackIndex.value].isPremium &&
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
                          _currentTrackIndex.value >= 0 && _currentTrackIndex.value < widget.featuredTips.length
                              ? widget.featuredTips[_currentTrackIndex.value].tipsAuthor
                              : "Unknown Artist",
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
                    // Always show playback controls
                    _buildPlaybackControls(isDarkMode),
                    SizedBox(height: 20.h),

                    // Error message as a dismissible banner
                    if (_hasError)
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 24.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _errorMessage ?? AppLocalizations.of(context)!.errorLoadingAudio,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'Poppins',
                                  fontSize: 13.sp,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: AppColors.error,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                _safeSetState(() {
                                  _hasError = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
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

class WaveAnimation extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const WaveAnimation({Key? key, required this.isPlaying, required this.color}) : super(key: key);

  @override
  _WaveAnimationState createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation> with TickerProviderStateMixin {
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
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
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

class CustomAudioSlider extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<double>? onChanged;
  final bool isDarkMode;
  final bool isActive;

  const CustomAudioSlider({
    Key? key,
    required this.duration,
    required this.position,
    this.onChanged,
    required this.isDarkMode,
    this.isActive = true,
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
                progress: (position.inMilliseconds / (duration.inMilliseconds > 0 ? duration.inMilliseconds : 1)).clamp(0.0, 1.0),
                waveColor: AppColors.primary.withOpacity(0.1),
                progressColor: isActive ? AppColors.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: isActive ? AppColors.primary : Colors.grey,
              inactiveTrackColor: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              thumbColor: isActive ? AppColors.primary : Colors.grey,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
              trackHeight: 4.h,
              overlayColor: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.2),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
            ),
            child: Slider(
              value: position.inSeconds.toDouble().clamp(0, duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1),
              max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1,
              onChanged: isActive ? onChanged : null,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(
              _formatDuration(position),
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

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

    final waveWidth = 3.0;
    final waveSpacing = 2.0;
    final totalWidth = waveWidth + waveSpacing;
    final waveCount = (size.width / totalWidth).floor();

    // Create a pseudorandom but consistent pattern
    final random = math.Random(12345);

    for (int i = 0; i < waveCount; i++) {
      final x = i * totalWidth + waveWidth / 2;
      // Generate height based on position (taller in middle, shorter at ends)
      final normalizedPos = (i / waveCount) * 2; // 0 to 2
      final position = normalizedPos <= 1 ? normalizedPos : 2 - normalizedPos; // 0 to 1 to 0
      final randomOffset = random.nextDouble() * 0.4 - 0.2; // -0.2 to 0.2
      final heightFactor = 0.3 + 0.7 * position + randomOffset;

      final waveHeight = size.height * 0.7 * heightFactor;
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