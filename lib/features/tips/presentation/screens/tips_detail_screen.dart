import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:math';
import 'dart:developer' as dev; // Added for logging
import '../../../../core/config/routes/route_name.dart';
import '../../../favorites/data/models/favorite_model.dart';
import '../../data/models/tips_model.dart';
import '../../../../core/resources/colors.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../core/services/data_repository.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class TipsDetailScreen extends StatefulWidget {
  final TipModel? tip;
  final String categoryName;
  final String userId;
  final List<TipModel>? featuredTips;
  final bool allHealthTips;
  final bool allQuotes;

  const TipsDetailScreen({
    super.key,
    this.tip,
    required this.categoryName,
    required this.userId,
    this.featuredTips,
    this.allHealthTips = false,
    this.allQuotes = false,
  });

  @override
  State<TipsDetailScreen> createState() => _TipsDetailScreenState();
}

class _TipsDetailScreenState extends State<TipsDetailScreen> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late Map<String, bool> _favoriteStatus;
  late List<TipModel> _tipsInCategory;
  late int _currentIndex;
  bool _isSlideshowEnabled = false;
  bool _isSpeaking = false;
  bool _isFullScreen = false;
  bool _showFullScreenIcon = true;
  bool _showSwipeIndicator = true;
  late AnimationController _animationController;
  late Animation<double> _waveAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late PageController _pageController;
  Timer? _slideshowTimer;
  int _countdown = 5;
  final List<_HeartAnimation> _hearts = [];
  late AnimationController _heartAnimationController;
  late AnimationController _swipeAnimationController;
  late Animation<double> _swipeAnimation;
  Future<void>? _fetchFuture; // Added for async fetching

  @override
  void initState() {
    super.initState();
    dev.log('TipsDetailScreen initialized with arguments: tipId=${widget.tip?.tipsId}, '
        'tipTitle=${widget.tip?.tipsTitle}, categoryName=${widget.categoryName}, '
        'featuredTipsLength=${widget.featuredTips?.length}, '
        'allHealthTips=${widget.allHealthTips}, allQuotes=${widget.allQuotes}');

    _favoriteStatus = {};
    _tipsInCategory = widget.featuredTips?.isNotEmpty == true
        ? widget.featuredTips!
        : widget.tip != null
        ? [widget.tip!]
        : [];
    _currentIndex = widget.featuredTips?.isNotEmpty == true
        ? widget.featuredTips!.indexWhere((t) => t.tipsId == widget.tip?.tipsId)
        : 0;
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize _fetchFuture based on conditions
    if (widget.allHealthTips) {
      _fetchFuture = _fetchAllHealthTips();
    } else if (widget.allQuotes) {
      _fetchFuture = _fetchAllQuotes();
    } else if (widget.featuredTips == null || widget.featuredTips!.isEmpty) {
      _fetchFuture = _fetchTipsInCategory();
    } else {
      _fetchFuture = Future.value(); // No async fetch needed for featuredTips
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waveAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
      if (mounted && status == AnimationStatus.completed && _isSlideshowEnabled) {
        _animationController.reverse();
      } else if (mounted && status == AnimationStatus.dismissed && _isSlideshowEnabled) {
        _animationController.forward();
      }
    });
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() {
      if (mounted) {
        setState(() {});
        if (_heartAnimationController.isCompleted) {
          _hearts.clear();
        }
      }
    });
    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _swipeAnimation = Tween<double>(begin: 0, end: 8.h).animate(
      CurvedAnimation(
        parent: _swipeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _setupTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoriteStatus();
    });
  }

  Future<void> _setupTts() async {
    try {
      final isTtsAvailable = await _tts.isLanguageAvailable('en-US');
      if (!isTtsAvailable && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text-to-speech not available on this device')),
          );
        });
        return;
      }
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      _tts.setStartHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = true);
          _pulseAnimationController.repeat(reverse: true);
        }
      });
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
          _pulseAnimationController.stop();
          _pulseAnimationController.reset();
        }
      });
      _tts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _pulseAnimationController.stop();
            _pulseAnimationController.reset();
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('TTS Error: $msg')),
            );
          });
        }
      });
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to initialize TTS: $e')),
          );
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (_tipsInCategory.isEmpty) return;
    try {
      final provider = Provider.of<FavoritesProvider>(context, listen: false);
      if (provider.favorites.isEmpty) {
        await provider.loadFavorites(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        for (var tip in _tipsInCategory) {
          _favoriteStatus[tip.tipsId] = provider.favorites.any((f) => f.tipId == tip.tipsId);
        }
      });
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading favorites: $e')),
          );
        });
      }
    }
  }

  Future<void> _fetchTipsInCategory() async {
    if (widget.tip == null || widget.tip!.categoryId.isEmpty) {
      dev.log('No tip or categoryId provided for _fetchTipsInCategory');
      return;
    }
    try {
      final tips = await DataRepository.instance.getTipsByCategory(widget.tip!.categoryId);
      dev.log('Fetched ${tips.length} tips for category ${widget.tip!.categoryId}');
      if (mounted) {
        setState(() {
          _tipsInCategory = tips.isNotEmpty ? tips : [widget.tip!];
          _currentIndex = tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId);
          if (_currentIndex == -1) _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        await _checkFavoriteStatus();
      }
    } catch (e) {
      dev.log('Error fetching tips: $e');
      if (mounted) {
        setState(() {
          _tipsInCategory = widget.tip != null ? [widget.tip!] : [];
          _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching tips: $e')),
          );
        });
      }
    }
  }

  Future<void> _fetchAllHealthTips() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tips')
          .where('tipsType', isEqualTo: 'healthTips')
          .get();
      final tips = snapshot.docs
          .map((doc) => TipModel.fromFirestore(doc.data(), doc.id))
          .toList();
      dev.log('Fetched ${tips.length} health tips');
      if (mounted) {
        setState(() {
          _tipsInCategory = tips.isNotEmpty ? tips : widget.tip != null ? [widget.tip!] : [];
          _currentIndex = widget.tip != null
              ? tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId)
              : 0;
          if (_currentIndex == -1) _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        await _checkFavoriteStatus();
      }
    } catch (e) {
      dev.log('Error fetching health tips: $e');
      if (mounted) {
        setState(() {
          _tipsInCategory = widget.tip != null ? [widget.tip!] : [];
          _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching health tips: $e')),
          );
        });
      }
    }
  }

  Future<void> _fetchAllQuotes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tips')
          .where('tipsType', isEqualTo: 'quote')
          .get();
      final tips = snapshot.docs
          .map((doc) => TipModel.fromFirestore(doc.data(), doc.id))
          .toList();
      dev.log('Fetched ${tips.length} quotes');
      if (mounted) {
        setState(() {
          _tipsInCategory = tips.isNotEmpty ? tips : widget.tip != null ? [widget.tip!] : [];
          _currentIndex = widget.tip != null
              ? tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId)
              : 0;
          if (_currentIndex == -1) _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        await _checkFavoriteStatus();
      }
    } catch (e) {
      dev.log('Error fetching quotes: $e');
      if (mounted) {
        setState(() {
          _tipsInCategory = widget.tip != null ? [widget.tip!] : [];
          _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching quotes: $e')),
          );
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_tipsInCategory.isEmpty) return;

    final authService = AuthService();
    final user = authService.getCurrentUser();
    if (user == null) {
      dev.log('No authenticated user found, redirecting to login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
      );
      Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      return;
    }

    final userId = user.uid;
    final tipId = _tipsInCategory[_currentIndex].tipsId;
    final wasFavorite = _favoriteStatus[tipId] ?? false;

    try {
      final provider = Provider.of<FavoritesProvider>(context, listen: false);
      setState(() {
        _favoriteStatus[tipId] = !wasFavorite;
        if (!wasFavorite) {
          _hearts.clear();
          for (int i = 0; i < 10; i++) {
            _hearts.add(_HeartAnimation(
              Random().nextDouble() * 100.w,
              Random().nextDouble() * 30 + 15,
            ));
          }
          _heartAnimationController.forward(from: 0);
        }
      });
      if (!wasFavorite) {
        final favorite = FavoriteModel(
          id: const Uuid().v4(),
          userId: userId,
          tipId: tipId,
          createdAt: DateTime.now(),
        );
        await provider.addFavorite(favorite);
        dev.log('Added favorite: ${favorite.id} for user $userId, tip $tipId');
      } else {
        final favorite = provider.favorites.firstWhere((f) => f.tipId == tipId);
        await provider.deleteFavorite(favorite.id);
        dev.log('Removed favorite: ${favorite.id} for user $userId, tip $tipId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoriteStatus[tipId] = wasFavorite;
          _hearts.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite: $e')),
        );
        dev.log('Error updating favorite for user $userId, tip $tipId: $e');
      }
    }
  }

  void _nextTip() {
    if (_tipsInCategory.isEmpty || _currentIndex >= _tipsInCategory.length - 1) {
      setState(() {
        _isSlideshowEnabled = false;
        _slideshowTimer?.cancel();
        _animationController.stop();
        _animationController.reset();
      });
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _resetSlideshowTimer();
  }

  void _previousTip() {
    if (_tipsInCategory.isEmpty || _currentIndex <= 0) return; // Added _currentIndex <= 0 check
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _resetSlideshowTimer();
  }

  Future<void> _readAloud() async {
    if (_tipsInCategory.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No content to read aloud')),
        );
      }
      return;
    }
    try {
      final tip = _tipsInCategory[_currentIndex];
      final text = tip.tipsType == 'quote' ? tip.tipsTitle : "${tip.tipsTitle}. ${tip.tipsDescription}".trim();
      if (text.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No content to read aloud')),
        );
        return;
      }
      if (_isSpeaking) {
        await _tts.pause();
        setState(() => _isSpeaking = false);
        _pulseAnimationController.stop();
        _pulseAnimationController.reset();
      } else {
        await _tts.stop();
        await _tts.speak(text);
        setState(() => _isSpeaking = true);
        _pulseAnimationController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _pulseAnimationController.stop();
          _pulseAnimationController.reset();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS Error: $e')),
        );
      }
    }
  }

  void _toggleSlideshow() {
    if (_tipsInCategory.isEmpty) return;
    setState(() {
      _isSlideshowEnabled = !_isSlideshowEnabled;
      if (_isSlideshowEnabled) {
        if (_currentIndex >= _tipsInCategory.length - 1) {
          _currentIndex = 0;
          _pageController.jumpToPage(0);
        }
        _isFullScreen = true;
        _animationController.forward();
        _startSlideshowTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slideshow started'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _isFullScreen = false;
        _animationController.stop();
        _animationController.reset();
        _slideshowTimer?.cancel();
        _countdown = 5;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slideshow paused'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown == 0) {
          _nextTip();
        }
      });
    });
  }

  void _resetSlideshowTimer() {
    if (_isSlideshowEnabled && _currentIndex < _tipsInCategory.length - 1) {
      setState(() {
        _countdown = 5;
      });
      _startSlideshowTimer();
    }
  }

  void _showTimerSettings() {
    int tempCountdown = _countdown;
    bool tempShowFullScreenIcon = _showFullScreenIcon;
    bool tempShowSwipeIndicator = _showSwipeIndicator;
    bool showAdvancedSettings = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              elevation: 8,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 24.h,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 24.sp),
                            onPressed: () => Navigator.pop(context),
                            splashRadius: 24.r,
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      _buildSectionHeader(
                        context,
                        'Slideshow Duration',
                        Icons.timer,
                      ),
                      SizedBox(height: 16.h),
                      _buildSliderSection(
                        context,
                        tempCountdown,
                            (value) => setState(() => tempCountdown = value),
                      ),
                      SizedBox(height: 24.h),
                      _buildSectionHeader(
                        context,
                        'Display Options',
                        Icons.settings,
                      ),
                      SizedBox(height: 16.h),
                      _buildToggleOption(
                        context,
                        'Show Full-Screen Icon',
                        tempShowFullScreenIcon,
                            (value) => setState(() => tempShowFullScreenIcon = value),
                      ),
                      SizedBox(height: 8.h),
                      _buildToggleOption(
                        context,
                        'Show Swipe Indicator',
                        tempShowSwipeIndicator,
                            (value) => setState(() => tempShowSwipeIndicator = value),
                      ),
                      SizedBox(height: 8.h),
                      _buildToggleOption(
                        context,
                        'Advanced Settings',
                        showAdvancedSettings,
                            (value) => setState(() => showAdvancedSettings = value),
                      ),
                      if (showAdvancedSettings) ...[
                        SizedBox(height: 24.h),
                        _buildSectionHeader(
                          context,
                          'Advanced Settings',
                          Icons.build,
                        ),
                        SizedBox(height: 16.h),
                        _buildToggleOption(
                          context,
                          'Enable Animations',
                          true,
                              (value) {},
                        ),
                        SizedBox(height: 8.h),
                        _buildToggleOption(
                          context,
                          'Dark Mode',
                          Theme.of(context).brightness == Brightness.dark,
                              (value) {},
                        ),
                      ],
                      SizedBox(height: 32.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _countdown = tempCountdown;
                                _showFullScreenIcon = tempShowFullScreenIcon;
                                _showSwipeIndicator = tempShowSwipeIndicator;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
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
      },
    ).then((_) {
      if (_isSlideshowEnabled) {
        _resetSlideshowTimer();
      }
    });
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSection(BuildContext context, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set slideshow transition speed (3-30 seconds)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  min: 3,
                  max: 30,
                  divisions: 27,
                  label: '$value seconds',
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primary.withOpacity(0.3),
                  onChanged: (val) => onChanged(val.toInt()),
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                width: 80.w,
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$value s',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3s',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '30s',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      BuildContext context,
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.5),
              inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              inactiveTrackColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _animationController.dispose();
    _heartAnimationController.dispose();
    _swipeAnimationController.dispose();
    _pulseAnimationController.dispose();
    _pageController.dispose();
    _slideshowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? null : AppColors.lightBackground,
        gradient: isDarkMode
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[850]!, Colors.grey[900]!],
        )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _isFullScreen
            ? null
            : PreferredSize(
          preferredSize: Size.fromHeight(64.h),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey[850]!, Colors.grey[900]!],
                  )
                      : null,
                  color: isDarkMode ? null : AppColors.lightBackground,
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
                        Icons.arrow_back_ios,
                        size: 24.sp,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.categoryName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        size: 24.sp,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      onPressed: _showTimerSettings,
                      tooltip: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<void>(
            future: _fetchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading tips: ${snapshot.error}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16.sp,
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (widget.allHealthTips) {
                              _fetchFuture = _fetchAllHealthTips();
                            } else if (widget.allQuotes) {
                              _fetchFuture = _fetchAllQuotes();
                            } else if (widget.featuredTips == null || widget.featuredTips!.isEmpty) {
                              _fetchFuture = _fetchTipsInCategory();
                            }
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (_tipsInCategory.isEmpty) {
                return Center(
                  child: Text(
                    'No tips available.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.sp,
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              }

              // Validate _currentIndex to prevent RangeError
              if (_currentIndex >= _tipsInCategory.length) {
                _currentIndex = 0;
                _pageController = PageController(initialPage: _currentIndex);
              }

              // Log the current tip
              dev.log('Displaying tip: id=${_tipsInCategory[_currentIndex].tipsId}, '
                  'title=${_tipsInCategory[_currentIndex].tipsTitle}, '
                  'index=$_currentIndex, totalTips=${_tipsInCategory.length}');

              return Consumer<FavoritesProvider>(
                builder: (context, provider, child) {
                  final currentTip = _tipsInCategory[_currentIndex];
                  final isFavorite = _favoriteStatus[currentTip.tipsId] ?? false;
                  final iconColor = isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _tipsInCategory.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                      _resetSlideshowTimer();
                    },
                    itemBuilder: (context, index) {
                      final tip = _tipsInCategory[index];
                      return Stack(
                        children: [
                          Container(
                            margin: _isFullScreen
                                ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h)
                                : EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDarkMode
                                    ? [Colors.grey[850]!, Colors.grey[900]!]
                                    : [Colors.white, Colors.grey.shade100],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                width: 1.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? AppColors.shadow.withOpacity(0.5) : AppColors.lightTextPrimary.withOpacity(0.2),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: EdgeInsets.all(_isFullScreen ? 16.w : 24.w),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(12.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4.r,
                                                offset: Offset(0, 2.h),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${index + 1}/${_tipsInCategory.length}',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(30.r),
                                            onTap: _tipsInCategory.isEmpty ? null : _readAloud,
                                            child: AnimatedBuilder(
                                              animation: Listenable.merge([_waveAnimation, _pulseAnimation]),
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: _isSpeaking ? _pulseAnimation.value : _waveAnimation.value,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: _isSpeaking
                                                          ? (isDarkMode
                                                          ? Colors.grey.shade800.withOpacity(0.7)
                                                          : Colors.grey.shade200.withOpacity(0.7))
                                                          : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.2),
                                                          blurRadius: 6.r,
                                                          offset: Offset(0, 2.h),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(8.w),
                                                      child: Icon(
                                                        _isSpeaking ? Icons.volume_off : Icons.volume_up,
                                                        size: 28.sp,
                                                        color: isDarkMode
                                                            ? AppColors.darkTextPrimary
                                                            : AppColors.lightTextPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: tip.tipsType == 'quote' ? 140.h : 48.h),
                                    child: Column(
                                      mainAxisAlignment: tip.tipsType == 'quote'
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (tip.tipsType != 'quote')
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tip.tipsTitle,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 26.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode
                                                      ? AppColors.darkTextPrimary
                                                      : AppColors.lightTextPrimary,
                                                ),
                                              ),
                                              SizedBox(height: 16.h),
                                              Text(
                                                tip.tipsDescription,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16.sp,
                                                  color: isDarkMode
                                                      ? AppColors.darkTextSecondary
                                                      : AppColors.lightTextSecondary,
                                                  height: 1.5,
                                                ),
                                              ),
                                              SizedBox(height: 16.h),
                                              if (tip.authorIcon != null || tip.tipsAuthor.isNotEmpty)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (tip.authorIcon != null)
                                                      Transform.translate(
                                                        offset: Offset(2.w, 0),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: isDarkMode
                                                                  ? Colors.grey.shade600
                                                                  : Colors.grey.shade400,
                                                              width: 1.5.w,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: isDarkMode
                                                                    ? Colors.grey.shade400.withOpacity(0.3)
                                                                    : Colors.grey.shade300.withOpacity(0.4),
                                                                blurRadius: 8.r,
                                                                spreadRadius: 2.r,
                                                                offset: Offset(0, 0),
                                                              ),
                                                            ],
                                                          ),
                                                          child: CircleAvatar(
                                                            radius: 24.r,
                                                            backgroundImage: NetworkImage(tip.authorIcon!),
                                                            backgroundColor: isDarkMode
                                                                ? Colors.grey.shade700
                                                                : Colors.grey.shade200,
                                                          ),
                                                        ),
                                                      ),
                                                    if (tip.authorIcon != null) SizedBox(width: 12.w),
                                                    Flexible(
                                                      child: Text(
                                                        tip.tipsAuthor,
                                                        style: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 16.sp,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDarkMode
                                                              ? AppColors.darkTextPrimary
                                                              : AppColors.lightTextPrimary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        if (tip.tipsType == 'quote')
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              RichText(
                                                textAlign: TextAlign.center,
                                                text: TextSpan(
                                                  children: [
                                                    WidgetSpan(
                                                      alignment: PlaceholderAlignment.baseline,
                                                      baseline: TextBaseline.alphabetic,
                                                      child: Text(
                                                        '“',
                                                        style: TextStyle(
                                                          fontFamily: 'PlayfairDisplay',
                                                          fontSize: 26.sp,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDarkMode
                                                              ? AppColors.darkTextPrimary
                                                              : AppColors.lightTextPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: tip.tipsTitle,
                                                      style: TextStyle(
                                                        fontFamily: 'Nunito',
                                                        fontSize: 24.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDarkMode
                                                            ? AppColors.darkTextPrimary
                                                            : AppColors.lightTextPrimary,
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                    WidgetSpan(
                                                      alignment: PlaceholderAlignment.baseline,
                                                      baseline: TextBaseline.alphabetic,
                                                      child: Text(
                                                        '”',
                                                        style: TextStyle(
                                                          fontFamily: 'PlayfairDisplay',
                                                          fontSize: 26.sp,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDarkMode
                                                              ? AppColors.darkTextPrimary
                                                              : AppColors.lightTextPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (tip.authorIcon != null || tip.tipsAuthor.isNotEmpty)
                                                Column(
                                                  children: [
                                                    SizedBox(height: 25.h),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (tip.authorIcon != null)
                                                          Transform.translate(
                                                            offset: Offset(10.w, 0),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                border: Border.all(
                                                                  color: isDarkMode
                                                                      ? Colors.grey.shade600
                                                                      : Colors.grey.shade400,
                                                                  width: 1.5.w,
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: isDarkMode
                                                                        ? Colors.grey.shade400.withOpacity(0.3)
                                                                        : Colors.grey.shade300.withOpacity(0.4),
                                                                    blurRadius: 8.r,
                                                                    spreadRadius: 2.r,
                                                                    offset: Offset(0, 0),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: CircleAvatar(
                                                                radius: 24.r,
                                                                backgroundImage: NetworkImage(tip.authorIcon!),
                                                                backgroundColor: isDarkMode
                                                                    ? Colors.grey.shade700
                                                                    : Colors.grey.shade200,
                                                              ),
                                                            ),
                                                          ),
                                                        if (tip.authorIcon != null) SizedBox(width: 22.w),
                                                        Flexible(
                                                          child: Text(
                                                            tip.tipsAuthor,
                                                            style: TextStyle(
                                                              fontFamily: 'Poppins',
                                                              fontSize: 16.sp,
                                                              fontWeight: FontWeight.w600,
                                                              color: isDarkMode
                                                                  ? AppColors.darkTextPrimary
                                                                  : AppColors.lightTextPrimary,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (_currentIndex < _tipsInCategory.length - 1 && _showSwipeIndicator)
                                    Positioned(
                                      bottom: 120.h,
                                      left: 0,
                                      right: 0,
                                      child: AnimatedBuilder(
                                        animation: _swipeAnimation,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(0, _swipeAnimation.value),
                                            child: Center(
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 600),
                                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      isDarkMode
                                                          ? Colors.grey.shade800.withOpacity(0.7)
                                                          : Colors.grey.shade200.withOpacity(0.7),
                                                      isDarkMode
                                                          ? Colors.grey.shade900.withOpacity(0.5)
                                                          : Colors.grey.shade100.withOpacity(0.5),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(16.r),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 6.r,
                                                      offset: Offset(0, 3.h),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_upward,
                                                      size: 18.sp,
                                                      color: isDarkMode
                                                          ? AppColors.darkTextSecondary
                                                          : AppColors.lightTextSecondary,
                                                    ),
                                                    SizedBox(width: 6.w),
                                                    Text(
                                                      'Swipe up for next ${widget.allQuotes || (widget.featuredTips?.isNotEmpty == true && widget.categoryName == 'Recently Added Quotes') ? 'quote' : 'tip'}',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 14.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDarkMode
                                                            ? AppColors.darkTextSecondary
                                                            : AppColors.lightTextSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 24.h,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildActionButton(
                                          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: isFavorite
                                              ? Colors.redAccent
                                              : (isDarkMode
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                          onPressed: _toggleFavorite,
                                          tooltip: isFavorite ? 'Remove Favorite' : 'Add Favorite',
                                        ),
                                        SizedBox(width: 20.w),
                                        _buildActionButton(
                                          icon: Icons.share,
                                          color: isDarkMode
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                          onPressed: () => Share.share(
                                            '${tip.tipsTitle}\n${tip.tipsDescription}',
                                          ),
                                          tooltip: 'Share',
                                        ),
                                        SizedBox(width: 20.w),
                                        AnimatedBuilder(
                                          animation: _animationController,
                                          builder: (context, child) {
                                            return _buildActionButton(
                                              icon: _isSlideshowEnabled ? Icons.pause : Icons.play_arrow,
                                              color: isDarkMode
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                              onPressed: _toggleSlideshow,
                                              tooltip: _isSlideshowEnabled ? 'Pause Slideshow' : 'Start Slideshow',
                                              child: _isSlideshowEnabled
                                                  ? Center(
                                                child: Text(
                                                  '$_countdown',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 16.sp,
                                                    color: isDarkMode
                                                        ? AppColors.darkTextPrimary
                                                        : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                              )
                                                  : Icon(
                                                Icons.play_arrow,
                                                size: 28.sp,
                                                color: isDarkMode
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                              ),
                                            );
                                          },
                                        ),
                                        if (_showFullScreenIcon)
                                          Row(
                                            children: [
                                              SizedBox(width: 20.w),
                                              _buildActionButton(
                                                icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                                color: isDarkMode
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                                onPressed: _toggleFullScreen,
                                                tooltip: _isFullScreen ? 'Exit Full Screen' : 'Enter Full Screen',
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          for (final heart in _hearts)
                            Positioned(
                              bottom: 100.h,
                              left: heart.xOffset,
                              child: _HeartWidget(
                                animation: _heartAnimationController,
                                size: heart.size,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: (Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary)
              .withOpacity(0.3),
          width: 1.5.w,
        ),
      ),
      child: IconButton(
        icon: child ?? Icon(icon, size: 28.sp, color: color),
        onPressed: _tipsInCategory.isEmpty ? null : onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _HeartAnimation {
  final double xOffset;
  final double size;

  _HeartAnimation(this.xOffset, this.size);
}

class _HeartWidget extends StatelessWidget {
  final AnimationController animation;
  final double size;

  const _HeartWidget({required this.animation, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        final yOffset = -progress * 300.h;
        final opacity = 1.0 - progress;
        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Icon(
              Icons.favorite,
              color: Colors.redAccent.withOpacity(0.8),
              size: size.sp,
            ),
          ),
        );
      },
    );
  }
}