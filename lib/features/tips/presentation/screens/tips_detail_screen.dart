import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../favorites/data/models/favorite_model.dart';
import '../../data/models/tips_model.dart';
import '../../../../core/resources/colors.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../data/services/tips_service.dart';
import '../../../auth/data/services/auth_service.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/settings_dialog_widget.dart';
import '../../../subscription/presentation/providers/premium_status_provider.dart';
import '../../../../core/config/routes/route_name.dart';
import 'dart:ui';

class TipsDetailScreen extends StatefulWidget {
  final TipModel? tip;
  final String categoryName;
  final String? userId;
  final List<TipModel>? featuredTips;
  final bool allHealthTips;
  final bool allQuotes;

  const TipsDetailScreen({
    super.key,
    this.tip,
    required this.categoryName,
    this.userId,
    this.featuredTips,
    this.allHealthTips = false,
    this.allQuotes = false,
  });

  @override
  State<TipsDetailScreen> createState() => _TipsDetailScreenState();
}

class _TipsDetailScreenState extends State<TipsDetailScreen> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final TipsService _tipsService = TipsService();
  final AuthService _authService = AuthService();
  String? _userId;
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
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;
  Future<void>? _fetchFuture;

  @override
  void initState() {
    super.initState();
    _userId = _authService.getCurrentUser()?.uid;
    dev.log(
      'TipsDetailScreen initialized with arguments: tipId=${widget.tip?.tipsId}, '
          'tipTitle=${widget.tip?.tipsTitle}, categoryName=${widget.categoryName}, '
          'userId=$_userId, featuredTipsLength=${widget.featuredTips?.length}, '
          'allHealthTips=${widget.allHealthTips}, allQuotes=${widget.allQuotes}',
    );

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

    if (widget.allHealthTips) {
      _fetchFuture = _tipsService.fetchAllHealthTips().then((tips) {
        if (mounted) {
          setState(() {
            _tipsInCategory = tips.isNotEmpty ? tips : widget.tip != null ? [widget.tip!] : [];
            _currentIndex = widget.tip != null ? tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId) : 0;
            if (_currentIndex == -1) _currentIndex = 0;
            _pageController = PageController(initialPage: _currentIndex);
          });
          _checkFavoriteStatus();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _tipsInCategory = widget.tip != null ? [widget.tip!] : [];
            _currentIndex = 0;
            _pageController = PageController(initialPage: _currentIndex);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching health tips: $e')),
          );
        }
      });
    } else if (widget.allQuotes) {
      _fetchFuture = _tipsService.fetchAllQuotes().then((tips) {
        if (mounted) {
          setState(() {
            _tipsInCategory = tips.isNotEmpty ? tips : widget.tip != null ? [widget.tip!] : [];
            _currentIndex = widget.tip != null ? tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId) : 0;
            if (_currentIndex == -1) _currentIndex = 0;
            _pageController = PageController(initialPage: _currentIndex);
          });
          _checkFavoriteStatus();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _tipsInCategory = widget.tip != null ? [widget.tip!] : [];
            _currentIndex = 0;
            _pageController = PageController(initialPage: _currentIndex);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching quotes: $e')),
          );
        }
      });
    } else if (widget.featuredTips == null || widget.featuredTips!.isEmpty) {
      _fetchFuture = _tipsService.fetchTipsInCategory(widget.tip!.categoryId).then((tips) {
        if (mounted) {
          setState(() {
            _tipsInCategory = tips.isNotEmpty ? tips : [widget.tip!];
            _currentIndex = tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId);
            if (_currentIndex == -1) _currentIndex = 0;
            _pageController = PageController(initialPage: _currentIndex);
          });
          _checkFavoriteStatus();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _tipsInCategory = widget.tip != null ? [widget.tip!] : [];
            _currentIndex = 0;
            _pageController = PageController(initialPage: _currentIndex);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching tips: $e')),
          );
        }
      });
    } else {
      _fetchFuture = Future.value();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waveAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
      CurvedAnimation(parent: _swipeAnimationController, curve: Curves.easeInOut),
    );
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -0.05), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -0.05, end: 0.05), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 0), weight: 25),
    ]).animate(_shakeController);
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _sparkleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TTS Error: $msg')),
          );
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
    if (_tipsInCategory.isEmpty || _userId == null || _userId!.isEmpty) {
      dev.log('checkFavoriteStatus: Skipping due to empty tips or userId');
      return;
    }
    try {
      final provider = Provider.of<FavoritesProvider>(context, listen: false);
      if (provider.favorites.isEmpty) {
        await provider.loadFavorites(_userId!);
      }
      if (!mounted) return;
      setState(() {
        for (var tip in _tipsInCategory) {
          _favoriteStatus[tip.tipsId] = provider.favorites.any((f) => f.tipId == tip.tipsId);
        }
      });
      dev.log('checkFavoriteStatus: Updated favorite status for ${_tipsInCategory.length} tips');
    } catch (e) {
      if (mounted) {
        dev.log('checkFavoriteStatus: Error loading favorites: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_tipsInCategory.isEmpty) {
      dev.log('toggleFavorite: No tips available');
      return;
    }

    if (_userId == null || _userId!.isEmpty) {
      dev.log('toggleFavorite: Invalid userId, checking authentication');
      if (!await _tipsService.checkUserAuthentication(context)) {
        return;
      }
      _userId = _authService.getCurrentUser()?.uid;
      if (_userId == null || _userId!.isEmpty) {
        dev.log('toggleFavorite: UserId still empty after authentication check');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to authenticate user')),
        );
        return;
      }
    }

    final tipId = _tipsInCategory[_currentIndex].tipsId;
    final wasFavorite = _favoriteStatus[tipId] ?? false;
    final provider = Provider.of<FavoritesProvider>(context, listen: false);

    try {
      setState(() {
        _favoriteStatus[tipId] = !wasFavorite;
      });

      // Add heart animation
      if (!wasFavorite) {
        _animateHearts();
      }

      await _tipsService.toggleFavorite(_userId!, tipId, provider, wasFavorite);
      dev.log('toggleFavorite: Successfully toggled favorite for tip $tipId, userId: $_userId');
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoriteStatus[tipId] = wasFavorite;
        });
        dev.log('toggleFavorite: Error updating favorite for tip $tipId: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite: $e')),
        );
      }
    }
  }

  void _animateHearts() {
    final screenWidth = MediaQuery.of(context).size.width;
    final random = Random();

    for (int i = 0; i < 8; i++) {
      _hearts.add(_HeartAnimation(
        xOffset: random.nextDouble() * screenWidth * 0.8,
        size: random.nextDouble() * 20 + 20,
      ));
    }

    _heartAnimationController.forward(from: 0);
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
    if (_tipsInCategory.isEmpty || _currentIndex <= 0) return;
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
      final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
      if (tip.isPremium && !canAccessPremium) {
        _showPremiumDialog(context);
        return;
      }
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
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
    final currentTip = _tipsInCategory[_currentIndex];
    if (currentTip.isPremium && !canAccessPremium) {
      _showPremiumDialog(context);
      return;
    }
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
          const SnackBar(content: Text('Slideshow started'), duration: Duration(seconds: 2)),
        );
      } else {
        _isFullScreen = false;
        _animationController.stop();
        _animationController.reset();
        _slideshowTimer?.cancel();
        _countdown = 5;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slideshow paused'), duration: Duration(seconds: 2)),
        );
      }
    });
  }

  void _toggleFullScreen() {
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
    final currentTip = _tipsInCategory[_currentIndex];
    if (currentTip.isPremium && !canAccessPremium) {
      _showPremiumDialog(context);
      return;
    }
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
    showDialog(
      context: context,
      builder: (context) => SettingsDialogWidget(
        initialCountdown: _countdown,
        initialShowFullScreenIcon: _showFullScreenIcon,
        initialShowSwipeIndicator: _showSwipeIndicator,
        onSave: (countdown, showFullScreenIcon, showSwipeIndicator) {
          setState(() {
            _countdown = countdown;
            _showFullScreenIcon = showFullScreenIcon;
            _showSwipeIndicator = showSwipeIndicator;
          });
          if (_isSlideshowEnabled) {
            _resetSlideshowTimer();
          }
        },
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/svg/ic_crown.svg',
                width: 24.r,
                height: 24.r,
                semanticsLabel: 'Premium content',
              ),
              SizedBox(width: 8.w),
              Text(
                'Premium ${widget.allQuotes || (widget.featuredTips?.isNotEmpty == true && widget.categoryName == 'Recently Added Quotes') ? 'Quote' : 'Tip'}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Text(
            'Unlock this exclusive ${widget.allQuotes || (widget.featuredTips?.isNotEmpty == true && widget.categoryName == 'Recently Added Quotes') ? 'quote' : 'tip'} and more with a Premium subscription!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16.sp,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, RoutesName.subscriptionScreen);
              },
              style: theme.elevatedButtonTheme.style?.copyWith(
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                textStyle: MaterialStateProperty.all(
                  theme.textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: const Text('Subscribe'),
            ),
          ],
        );
      },
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
    _shakeController.dispose();
    _sparkleController.dispose();
    _slideshowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
        ),
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
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.categoryName,
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
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        size: 24.sp,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                              _fetchFuture = _tipsService.fetchAllHealthTips().then((tips) {
                                setState(() {
                                  _tipsInCategory = tips.isNotEmpty ? tips : widget.tip != null ? [widget.tip!] : [];
                                  _currentIndex = widget.tip != null
                                      ? tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId)
                                      : 0;
                                  if (_currentIndex == -1) _currentIndex = 0;
                                  _pageController = PageController(initialPage: _currentIndex);
                                });
                                _checkFavoriteStatus();
                              });
                            } else if (widget.allQuotes) {
                              _fetchFuture = _tipsService.fetchAllQuotes().then((tips) {
                                setState(() {
                                  _tipsInCategory = tips.isNotEmpty ? tips : widget.tip != null ? [widget.tip!] : [];
                                  _currentIndex = widget.tip != null
                                      ? tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId)
                                      : 0;
                                  if (_currentIndex == -1) _currentIndex = 0;
                                  _pageController = PageController(initialPage: _currentIndex);
                                });
                                _checkFavoriteStatus();
                              });
                            } else if (widget.featuredTips == null || widget.featuredTips!.isEmpty) {
                              _fetchFuture = _tipsService.fetchTipsInCategory(widget.tip!.categoryId).then((tips) {
                                setState(() {
                                  _tipsInCategory = tips.isNotEmpty ? tips : [widget.tip!];
                                  _currentIndex = tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId);
                                  if (_currentIndex == -1) _currentIndex = 0;
                                  _pageController = PageController(initialPage: _currentIndex);
                                });
                                _checkFavoriteStatus();
                              });
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

              if (_currentIndex >= _tipsInCategory.length) {
                _currentIndex = 0;
                _pageController = PageController(initialPage: _currentIndex);
              }

              dev.log(
                'Displaying tip: id=${_tipsInCategory[_currentIndex].tipsId}, '
                    'title=${_tipsInCategory[_currentIndex].tipsTitle}, '
                    'index=$_currentIndex, totalTips=${_tipsInCategory.length}',
              );

              return Consumer<FavoritesProvider>(
                builder: (context, provider, child) {
                  final currentTip = _tipsInCategory[_currentIndex];
                  final isFavorite = _favoriteStatus[currentTip.tipsId] ?? false;
                  return Consumer<PremiumStatusProvider>(
                    builder: (context, premiumStatus, child) {
                      final canAccessPremium = premiumStatus.canAccessPremium;
                      if (currentTip.isPremium && !canAccessPremium) {
                        _shakeController.repeat();
                      } else {
                        _shakeController.stop();
                      }
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
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
                                  ),
                                  border: Border.all(
                                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                    width: 2.w,
                                  ),
                                  borderRadius: BorderRadius.circular(18.r),
                                ),
                                child: Stack(
                                  children: [
                                    if (!(tip.isPremium && !canAccessPremium)) ...[
                                      TipContentWidget(
                                        tip: tip,
                                        isDarkMode: isDarkMode,
                                        isFullScreen: _isFullScreen,
                                        isFavorite: isFavorite,
                                      ),
                                    ],
                                    // Premium content overlay - KEEPING ORIGINAL DESIGN
                                    if (tip.isPremium && !canAccessPremium) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(18.r),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: isDarkMode
                                                    ? [
                                                  AppColors.darkSurface.withOpacity(0.8),
                                                  AppColors.darkSurface.withOpacity(0.6),
                                                ]
                                                    : [
                                                  AppColors.lightBackground.withOpacity(0.7),
                                                  AppColors.lightBackground.withOpacity(0.5),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: InkWell(
                                          onTap: () {
                                            _showPremiumDialog(context);
                                          },
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              AnimatedBuilder(
                                                animation: _shakeController,
                                                builder: (context, child) {
                                                  return Transform.rotate(
                                                    angle: _shakeAnimation.value,
                                                    child: SvgPicture.asset(
                                                      'assets/icons/svg/ic_crown.svg',
                                                      width: 60.r,
                                                      height: 60.r,
                                                      semanticsLabel: 'Premium content',
                                                    ),
                                                  );
                                                },
                                              ),
                                              SizedBox(height: 16.h),
                                              Text(
                                                'Unlock Premium Content',
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                                                  fontSize: 24.sp,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 8.h),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                                child: Text(
                                                  'Unlock this exclusive ${tip.tipsType == 'quote' ? 'quote' : 'tip'} and more with a Premium subscription!',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: isDarkMode
                                                        ? AppColors.darkTextSecondary
                                                        : AppColors.lightTextSecondary,
                                                    fontSize: 16.sp,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(height: 16.h),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pushNamed(context, RoutesName.subscriptionScreen);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isDarkMode ? AppColors.primary : Colors.black,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12.r),
                                                  ),
                                                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                                ),
                                                child: Text(
                                                  'Subscribe Now',
                                                  style: theme.textTheme.labelLarge?.copyWith(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 16.h),
                                              Positioned(
                                                top: -10.h,
                                                left: -10.w,
                                                child: AnimatedBuilder(
                                                  animation: _sparkleAnimation,
                                                  builder: (context, child) {
                                                    return Transform.scale(
                                                      scale: _sparkleAnimation.value,
                                                      child: Icon(
                                                        Icons.star,
                                                        size: 20.sp,
                                                        color: Colors.yellow.withOpacity(0.6),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              Positioned(
                                                bottom: -10.h,
                                                right: -10.w,
                                                child: AnimatedBuilder(
                                                  animation: _sparkleAnimation,
                                                  builder: (context, child) {
                                                    return Transform.scale(
                                                      scale: _sparkleAnimation.value * 0.8,
                                                      child: Icon(
                                                        Icons.star,
                                                        size: 16.sp,
                                                        color: Colors.yellow.withOpacity(0.6),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (!(tip.isPremium && !canAccessPremium)) ...[
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
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
                                      ),
                                      ActionButtonsWidget(
                                        isFavorite: isFavorite,
                                        isSlideshowEnabled: _isSlideshowEnabled,
                                        isFullScreen: _isFullScreen,
                                        showFullScreenIcon: _showFullScreenIcon,
                                        countdown: _countdown,
                                        isDarkMode: isDarkMode,
                                        onToggleFavorite: _toggleFavorite,
                                        onShare: () => Share.share('${tip.tipsTitle}\n${tip.tipsDescription}'),
                                        onToggleSlideshow: _toggleSlideshow,
                                        onToggleFullScreen: _toggleFullScreen,
                                        tip: tip,
                                      ),
                                    ],
                                    if (_currentIndex < _tipsInCategory.length - 1 && _showSwipeIndicator && !(tip.isPremium && !canAccessPremium))
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
                                  ],
                                ),
                              ),
                              for (final heart in _hearts)
                                Positioned(
                                  bottom: 100.h,
                                  left: heart.xOffset,
                                  child: _HeartWidget(animation: _heartAnimationController, size: heart.size),
                                ),
                            ],
                          );
                        },
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
}

class _HeartAnimation {
  final double xOffset;
  final double size;

  // Constructor with named parameters
  _HeartAnimation({
    required this.xOffset,
    required this.size,
  });

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

class TipContentWidget extends StatelessWidget {
  final TipModel tip;
  final bool isDarkMode;
  final bool isFullScreen;
  final bool isFavorite;

  const TipContentWidget({
    super.key,
    required this.tip,
    required this.isDarkMode,
    required this.isFullScreen,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuote = tip.tipsType == 'quote';
    final authorIconSize = isFullScreen ? (isQuote ? 56.r : 250.r) : (isQuote ? 48.r : 200.r);
    final contentTopPadding = isFullScreen ? 32.h : 24.h;

    return Container(
      padding: EdgeInsets.only(
        top: isQuote ? 60.h : (isFullScreen ? 24.w : 16.w),
        left: isFullScreen ? 24.w : 16.w,
        right: isFullScreen ? 24.w : 16.w,
        bottom: isFullScreen ? 24.w : 16.w,
      ),
      child: Column(
        mainAxisAlignment: isQuote ? MainAxisAlignment.center : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isQuote && (tip.authorIcon != null || tip.tipsAuthor.isNotEmpty)) ...[
            Padding(
              padding: EdgeInsets.only(top: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (tip.authorIcon != null)
                    Center(
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: tip.authorIcon!,
                          width: authorIconSize,
                          height: authorIconSize,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: authorIconSize,
                            height: authorIconSize,
                            color: isDarkMode ? AppColors.darkSurface.withOpacity(0.5) : Colors.grey[300],
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2.w)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: authorIconSize,
                            height: authorIconSize,
                            color: isDarkMode ? AppColors.darkSurface.withOpacity(0.5) : Colors.grey[300],
                            child: Icon(
                              Icons.broken_image,
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              size: authorIconSize / 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (tip.tipsAuthor.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      tip.tipsAuthor,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: contentTopPadding),
          Center(
            child: isQuote
                ? Transform.translate(
              offset: Offset(0, -20.h),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Text(
                        '"',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: isFullScreen ? 28.sp : 26.sp,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: tip.tipsTitle,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: isFullScreen ? 26.sp : 24.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        height: 1.2,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Text(
                        '"',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: isFullScreen ? 28.sp : 26.sp,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Text(
              tip.tipsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: isFullScreen ? 28.sp : 26.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (!isQuote) ...[
            SizedBox(height: 12.h),
            Flexible(
              child: Text(
                tip.tipsDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: isFullScreen ? 20.sp : 18.sp,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (isQuote && (tip.authorIcon != null || tip.tipsAuthor.isNotEmpty)) ...[
            SizedBox(height: 25.h),
            Transform.translate(
              offset: Offset(0, 25.h),
              child: Row(
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
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
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
                          radius: authorIconSize / 2,
                          backgroundImage: NetworkImage(tip.authorIcon!),
                          backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                        ),
                      ),
                    ),
                  if (tip.authorIcon != null) SizedBox(width: 22.w),
                  Flexible(
                    child: Text(
                      tip.tipsAuthor,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: isFullScreen ? 18.sp : 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}