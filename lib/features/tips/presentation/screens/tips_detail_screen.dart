import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../data/models/tips_model.dart';
import '../../../../core/resources/colors.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../data/services/tips_service.dart';
import '../../../auth/data/services/auth_service.dart';
import '../widgets/gradient_balls_widget.dart';
import '../widgets/heart_animation.dart';
import '../widgets/settings_dialog_widget.dart';
import '../../../subscription/presentation/providers/premium_status_provider.dart';
import '../../../../core/config/routes/route_name.dart';
import 'dart:ui';
import '../providers/settings_provider.dart';
import '../widgets/tips_content.dart';
import '../../../onboarding/domain/showcase_helper.dart';

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

class _TipsDetailScreenState extends State<TipsDetailScreen>
    with TickerProviderStateMixin {
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
  bool _showSwipeHint = false;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late PageController _pageController;
  Timer? _slideshowTimer;
  late AnimationController _heartAnimationController;
  late AnimationController _swipeAnimationController;
  late Animation<double> _swipeAnimation;
  Future<void>? _fetchFuture;
  final List<HeartAnimation> _hearts = [];
  int _countdown = 0;
  bool _isShowcaseInitialized = false;

  // Showcase global keys
  final GlobalKey _settingsShowcaseKey = GlobalKey();
  final GlobalKey _favoriteButtonShowcaseKey = GlobalKey();
  final GlobalKey _shareButtonShowcaseKey = GlobalKey();
  final GlobalKey _slideshowButtonShowcaseKey = GlobalKey();
  final GlobalKey _fullscreenButtonShowcaseKey = GlobalKey();
  final GlobalKey _swipeShowcaseKey = GlobalKey();
  final GlobalKey _ttsShowcaseKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _userId = _authService.getCurrentUser()?.uid;

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _countdown = settingsProvider.countdown;

    // Move state-changing call to a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      settingsProvider.incrementVisitCount();
    });

    if (settingsProvider.shouldShowSwipeIndicator) {
      _showSwipeHint = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSwipeHint = false;
          });
        }
      });
    }

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

    if (widget.allHealthTips ||
        widget.allQuotes ||
        (widget.featuredTips == null || widget.featuredTips!.isEmpty)) {
      _fetchFuture = _loadData();
    } else {
      _fetchFuture = Future.value();
    }

    _heartAnimationController =
        AnimationController(
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

    _pulseAnimationController =
        AnimationController(
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

  Future<void> _loadData() async {
    try {
      List<TipModel> tips = [];

      if (widget.allHealthTips) {
        tips = await _tipsService.fetchAllHealthTips();
      } else if (widget.allQuotes) {
        tips = await _tipsService.fetchAllQuotes();
      } else if (widget.tip != null) {
        tips = await _tipsService.fetchTipsInCategory(widget.tip!.categoryId);
      }

      if (mounted) {
        setState(() {
          _tipsInCategory = tips.isNotEmpty
              ? tips
              : widget.tip != null
              ? [widget.tip!]
              : [];
          _currentIndex = widget.tip != null
              ? tips.indexWhere((tip) => tip.tipsId == widget.tip!.tipsId)
              : 0;
          if (_currentIndex == -1) _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        _checkFavoriteStatus();
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _tipsInCategory = widget.tip != null ? [widget.tip!] : [];
          _currentIndex = 0;
          _pageController = PageController(initialPage: _currentIndex);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading content: $e')));
      }
      return;
    }
  }

  Future<void> _setupTts() async {
    try {
      final isTtsAvailable = await _tts.isLanguageAvailable('en-US');
      if (!isTtsAvailable && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text-to-speech not available on this device'),
            ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('TTS Error: $msg')));
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
          _favoriteStatus[tip.tipsId] = provider.favorites.any(
            (f) => f.tipId == tip.tipsId,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading favorites: $e')));
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_tipsInCategory.isEmpty) return;

    if (_userId == null || _userId!.isEmpty) {
      if (!await _tipsService.checkUserAuthentication(context)) {
        return;
      }
      _userId = _authService.getCurrentUser()?.uid;
      if (_userId == null || _userId!.isEmpty) {
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

      if (!wasFavorite) {
        _animateHearts();
      }

      await _tipsService.toggleFavorite(_userId!, tipId, provider, wasFavorite);
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoriteStatus[tipId] = wasFavorite;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating favorite: $e')));
      }
    }
  }

  void _animateHearts() {
    final screenWidth = MediaQuery.of(context).size.width;
    final random = Random();

    for (int i = 0; i < 8; i++) {
      _hearts.add(
        HeartAnimation(
          xOffset: random.nextDouble() * screenWidth * 0.8,
          size: random.nextDouble() * 20 + 20,
        ),
      );
    }

    _heartAnimationController.forward(from: 0);
  }

  void _nextTip() {
    if (_tipsInCategory.isEmpty ||
        _currentIndex >= _tipsInCategory.length - 1) {
      setState(() {
        _isSlideshowEnabled = false;
        _slideshowTimer?.cancel();
        _countdown = Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).countdown;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reached the last tip'),
            duration: Duration(seconds: 2),
          ),
        );
      });
      return;
    }
    _pageController.nextPage(
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
      final canAccessPremium = Provider.of<PremiumStatusProvider>(
        context,
        listen: false,
      ).canAccessPremium;
      if (tip.isPremium && !canAccessPremium) {
        _showPremiumDialog(context);
        return;
      }
      final text = tip.tipsType == 'quote'
          ? tip.tipsTitle
          : "${tip.tipsTitle}. ${tip.tipsDescription}".trim();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('TTS Error: $e')));
      }
    }
  }

  void _toggleSlideshow() {
    if (_tipsInCategory.isEmpty) return;
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    if (!settingsProvider.slideshowEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slideshow is disabled in settings')),
      );
      return;
    }
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
      listen: false,
    ).canAccessPremium;
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
        _startSlideshowTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slideshow started'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _isFullScreen = false;
        _slideshowTimer?.cancel();
        _countdown = settingsProvider.countdown;
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
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
      listen: false,
    ).canAccessPremium;
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
    if (_currentIndex >= _tipsInCategory.length - 1) {
      setState(() {
        _isSlideshowEnabled = false;
        _countdown = Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).countdown;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reached the last tip'),
            duration: Duration(seconds: 2),
          ),
        );
      });
      return;
    }
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    setState(() {
      _countdown = settingsProvider.countdown;
    });
    _slideshowTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        }
        if (_countdown == 0) {
          _nextTip();
          _countdown = settingsProvider.countdown;
        }
      });
    });
  }

  void _resetSlideshowTimer() {
    if (_isSlideshowEnabled && _currentIndex < _tipsInCategory.length - 1) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      setState(() {
        _countdown = settingsProvider.countdown;
      });
      _startSlideshowTimer();
    } else if (_isSlideshowEnabled &&
        _currentIndex >= _tipsInCategory.length - 1) {
      setState(() {
        _isSlideshowEnabled = false;
        _slideshowTimer?.cancel();
        _countdown = Provider.of<SettingsProvider>(
          context,
          listen: false,
        ).countdown;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reached the last tip'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _showTimerSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (context) => SettingsDialogWidget(
        initialCountdown: settingsProvider.countdown,
        initialShowFullScreenIcon: settingsProvider.showFullScreenIcon,
        initialShowSwipeIndicator: settingsProvider.showSwipeIndicator,
        initialSlideshowEnabled: settingsProvider.slideshowEnabled,
        onSave:
            (
              countdown,
              showFullScreenIcon,
              showSwipeIndicator,
              slideshowEnabled,
            ) {
              settingsProvider.updateSettings(
                countdown,
                showFullScreenIcon,
                showSwipeIndicator,
                slideshowEnabled,
              );
              if (_isSlideshowEnabled) {
                _resetSlideshowTimer();
              }
            },
      ),
    );
  }

  // Improved premium dialog
  void _showPremiumDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [Color(0xFF2D2D3A), Color(0xFF1D1D2B)]
                    : [Colors.white, Color(0xFFF8F9FA)],
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15.r,
                  spreadRadius: 5.r,
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20.r,
                  spreadRadius: 10.r,
                ),
              ],
              border: Border.all(
                color: isDarkMode
                    ? Colors.grey[700]!.withOpacity(0.5)
                    : Colors.grey[300]!.withOpacity(0.5),
                width: 1.w,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium crown with glow effect
                Container(
                  width: 120.r,
                  height: 120.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20.r,
                        spreadRadius: 5.r,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/svg/ic_crown.svg',
                      width: 80.r,
                      height: 80.r,
                      semanticsLabel: 'Premium content',
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Premium title with gradient
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [Colors.amber, Colors.orange, Colors.amber],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    'Unlock Premium Content',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 16.h),
                Text(
                  'Access exclusive premium content and elevate your wellness journey!',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Benefit bullet points
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[800]!.withOpacity(0.5)
                        : Colors.grey[100]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey[700]!.withOpacity(0.5)
                          : Colors.grey[300]!.withOpacity(0.5),
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitRow(
                        context,
                        Icons.check_circle_outline,
                        'Unlimited premium content',
                        isDarkMode,
                      ),
                      SizedBox(height: 8.h),
                      _buildBenefitRow(
                        context,
                        Icons.check_circle_outline,
                        'Ad-free experience',
                        isDarkMode,
                      ),
                      SizedBox(height: 8.h),
                      _buildBenefitRow(
                        context,
                        Icons.check_circle_outline,
                        'Exclusive wellness features',
                        isDarkMode,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey[300]!,
                            width: 1.w,
                          ),
                        ),
                      ),
                      child: Text(
                        'Not Now',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                    ),

                    // Subscribe button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8.r,
                            spreadRadius: 0,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            RoutesName.subscriptionScreen,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  Widget _buildBenefitRow(
    BuildContext context,
    IconData icon,
    String text,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.amber),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _heartAnimationController.dispose();
    _swipeAnimationController.dispose();
    _pulseAnimationController.dispose();
    _pageController.dispose();
    _slideshowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (showcaseContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isShowcaseInitialized &&
              _tipsInCategory.isNotEmpty &&
              mounted) {
            _isShowcaseInitialized = true;

            // Use a small delay to ensure all widgets are laid out
            Future.delayed(const Duration(milliseconds: 500), () {
              try {
                if (mounted) {
                  // Use the showcaseContext from ShowCaseWidget.builder
                  ShowcaseHelper.startShowcase(
                    showcaseContext,
                    // Use showcase context here instead of this.context
                    [
                      _settingsShowcaseKey,
                      _favoriteButtonShowcaseKey,
                      _shareButtonShowcaseKey,
                      _slideshowButtonShowcaseKey,
                      _fullscreenButtonShowcaseKey,
                      _ttsShowcaseKey, // Added TTS showcase key
                      _swipeShowcaseKey,
                    ],
                    [
                      'Settings',
                      'Like',
                      'Share',
                      'Slideshow',
                      'Fullscreen',
                      'Text to Speech',
                      'Navigation',
                    ],
                    [
                      'Customize slideshow timing and appearance settings',
                      'Add this tip to your favorites for easy access later',
                      'Share this tip with friends and family',
                      'Enable slideshow mode to automatically view all tips',
                      'Toggle fullscreen mode for better viewing experience',
                      'Listen to the tip content read aloud',
                      'Swipe up to see the next tip in this collection',
                    ],
                    showcaseKey: 'tips_detail_showcase',
                  );
                }
              } catch (e) {
                dev.log(
                  'Failed to start showcase: $e',
                  name: 'TipsDetailScreen',
                );
              }
            });
          }
        });

        return _buildScreenContent(showcaseContext);
      },
      autoPlayDelay: const Duration(seconds: 3),
      onFinish: () {
        dev.log('Showcase finished', name: 'TipsDetailScreen');
      },
    );
  }

  Widget _buildScreenContent(BuildContext showcaseContext) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Container(
      // Background gradient for the whole screen
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
                    // Match padding with content card
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          height: 56.h,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.2)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(22.r),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.25),
                              width: 1.5.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.15)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                spreadRadius: 1,
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
                              Showcase(
                                key: _settingsShowcaseKey,
                                title: 'Settings',
                                description:
                                    'Customize slideshow timing and appearance settings',
                                tooltipBackgroundColor: isDarkMode
                                    ? AppColors.darkSurface
                                    : AppColors.lightSurface,
                                textColor: isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                overlayColor: isDarkMode
                                    ? AppColors.overlay
                                    : Colors.grey.shade200,
                                titleTextStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                descTextStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                  color: isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                tooltipPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                targetPadding: EdgeInsets.all(8.w),
                                targetShapeBorder: const CircleBorder(),
                                child: IconButton(
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
                              ),
                            ],
                          ),
                        ),
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
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _fetchFuture = _loadData();
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
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                );
              }

              if (_currentIndex >= _tipsInCategory.length) {
                _currentIndex = 0;
                _pageController = PageController(initialPage: _currentIndex);
              }

              return Consumer<FavoritesProvider>(
                builder: (context, provider, child) {
                  final currentTip = _tipsInCategory[_currentIndex];
                  final isFavorite =
                      _favoriteStatus[currentTip.tipsId] ?? false;

                  return Consumer<PremiumStatusProvider>(
                    builder: (context, premiumStatus, child) {
                      final canAccessPremium = premiumStatus.canAccessPremium;

                      return Stack(
                        children: [
                          // Static gradient balls as background
                          Positioned.fill(
                            child: StaticGradientBalls(isDarkMode: isDarkMode),
                          ),

                          // PageView for content
                          Showcase(
                            key: _swipeShowcaseKey,
                            title: 'Navigation',
                            description:
                                'Swipe up to see the next tip in this collection',
                            tooltipBackgroundColor: isDarkMode
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            textColor: isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            overlayColor: isDarkMode
                                ? AppColors.overlay
                                : Colors.grey.shade200,
                            titleTextStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            descTextStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              color: isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            tooltipPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            targetPadding: EdgeInsets.all(8.w),
                            targetBorderRadius: BorderRadius.circular(22.r),
                            // This showcase is positioned in the middle of the page, not at the top
                            child: PageView.builder(
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
                                final isTipFavorite =
                                    _favoriteStatus[tip.tipsId] ?? false;

                                // Create a container with the entire card including buttons area
                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  // This is the key change - create a column that contains both
                                  // the content card and the buttons below it
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Main content container
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            if (!(tip.isPremium &&
                                                !canAccessPremium)) ...[
                                              // TipContentWidget
                                              TipContentWidget(
                                                tip: tip,
                                                isDarkMode: isDarkMode,
                                                isFullScreen: _isFullScreen,
                                              ),

                                              // Counter and audio button overlay
                                              Positioned(
                                                top: 15.h,
                                                left: 0,
                                                right: 0,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 2.h,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      // Glassmorphic counter
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        child: BackdropFilter(
                                                          filter:
                                                              ImageFilter.blur(
                                                                sigmaX: 5.0,
                                                                sigmaY: 5.0,
                                                              ),
                                                          child: Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12.w,
                                                                  vertical: 6.h,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: isDarkMode
                                                                  ? Colors.black
                                                                        .withOpacity(
                                                                          0.2,
                                                                        )
                                                                  : Colors.white
                                                                        .withOpacity(
                                                                          0.2,
                                                                        ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12.r,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    isDarkMode
                                                                    ? Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.08,
                                                                          )
                                                                    : Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.25,
                                                                          ),
                                                                width: 1.w,
                                                              ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color:
                                                                      isDarkMode
                                                                      ? Colors
                                                                            .black
                                                                            .withOpacity(
                                                                              0.1,
                                                                            )
                                                                      : Colors
                                                                            .black
                                                                            .withOpacity(
                                                                              0.05,
                                                                            ),
                                                                  blurRadius:
                                                                      4.r,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        2.h,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Text(
                                                              '${index + 1}/${_tipsInCategory.length}',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontSize: 12.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    isDarkMode
                                                                    ? AppColors
                                                                          .darkTextPrimary
                                                                    : AppColors
                                                                          .lightTextPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      // Glassmorphic audio button
                                                      // Add showcase for the TTS button
                                                      Showcase(
                                                        key: _ttsShowcaseKey,
                                                        title: 'Text to Speech',
                                                        description:
                                                            'Listen to the tip content read aloud',
                                                        tooltipBackgroundColor:
                                                            isDarkMode
                                                            ? AppColors
                                                                  .darkSurface
                                                            : AppColors
                                                                  .lightSurface,
                                                        textColor: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                        overlayColor: isDarkMode
                                                            ? AppColors.overlay
                                                            : Colors
                                                                  .grey
                                                                  .shade200,
                                                        titleTextStyle: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDarkMode
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                        descTextStyle: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 14.sp,
                                                          color: isDarkMode
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                        tooltipPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12.w,
                                                              vertical: 8.h,
                                                            ),
                                                        targetPadding:
                                                            EdgeInsets.all(8.w),
                                                        targetShapeBorder:
                                                            const CircleBorder(),
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  30.r,
                                                                ),
                                                            onTap: _readAloud,
                                                            child: AnimatedBuilder(
                                                              animation:
                                                                  _pulseAnimation,
                                                              builder: (context, child) {
                                                                return Transform.scale(
                                                                  scale:
                                                                      _isSpeaking
                                                                      ? _pulseAnimation
                                                                            .value
                                                                      : 1.0,
                                                                  child: ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          30.r,
                                                                        ),
                                                                    child: BackdropFilter(
                                                                      filter: ImageFilter.blur(
                                                                        sigmaX:
                                                                            5.0,
                                                                        sigmaY:
                                                                            5.0,
                                                                      ),
                                                                      child: Container(
                                                                        decoration: BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color:
                                                                              isDarkMode
                                                                              ? Colors.black.withOpacity(
                                                                                  0.2,
                                                                                )
                                                                              : Colors.white.withOpacity(0.2),
                                                                          border: Border.all(
                                                                            color:
                                                                                isDarkMode
                                                                                ? Colors.white.withOpacity(
                                                                                    0.08,
                                                                                  )
                                                                                : Colors.white.withOpacity(
                                                                                    0.25,
                                                                                  ),
                                                                            width:
                                                                                1.w,
                                                                          ),
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                              color: isDarkMode
                                                                                  ? Colors.black.withOpacity(
                                                                                      0.1,
                                                                                    )
                                                                                  : Colors.black.withOpacity(
                                                                                      0.05,
                                                                                    ),
                                                                              blurRadius: 4.r,
                                                                              offset: Offset(
                                                                                0,
                                                                                2.h,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        child: Padding(
                                                                          padding: EdgeInsets.all(
                                                                            8.w,
                                                                          ),
                                                                          child: Icon(
                                                                            _isSpeaking
                                                                                ? Icons.volume_off
                                                                                : Icons.volume_up,
                                                                            size:
                                                                                28.sp,
                                                                            color:
                                                                                isDarkMode
                                                                                ? AppColors.darkTextPrimary
                                                                                : AppColors.lightTextPrimary,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],

                                            // Premium content overlay
                                            if (tip.isPremium &&
                                                !canAccessPremium) ...[
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(22.r),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 5.0,
                                                    sigmaY: 5.0,
                                                  ),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: isDarkMode
                                                            ? [
                                                                Color(
                                                                  0xFF2D2D3A,
                                                                ).withOpacity(
                                                                  0.8,
                                                                ),
                                                                Color(
                                                                  0xFF1D1D2B,
                                                                ).withOpacity(
                                                                  0.8,
                                                                ),
                                                              ]
                                                            : [
                                                                Colors.white
                                                                    .withOpacity(
                                                                      0.8,
                                                                    ),
                                                                Color(
                                                                  0xFFF8F9FA,
                                                                ).withOpacity(
                                                                  0.8,
                                                                ),
                                                              ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            22.r,
                                                          ),
                                                      border: Border.all(
                                                        color: isDarkMode
                                                            ? Colors
                                                                  .grey
                                                                  .shade700
                                                                  .withOpacity(
                                                                    0.3,
                                                                  )
                                                            : Colors.white
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                        width: 1.5.w,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Premium lock content
                                              Positioned.fill(
                                                child: InkWell(
                                                  onTap: () {
                                                    _showPremiumDialog(context);
                                                  },
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      // Premium crown with glow effect
                                                      Container(
                                                        width: 100.r,
                                                        height: 100.r,
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.amber
                                                              .withOpacity(0.1),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .amber
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              blurRadius: 15.r,
                                                              spreadRadius: 2.r,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Center(
                                                          child: SvgPicture.asset(
                                                            'assets/icons/svg/ic_crown.svg',
                                                            width: 60.r,
                                                            height: 60.r,
                                                            semanticsLabel:
                                                                'Premium content',
                                                          ),
                                                        ),
                                                      ),

                                                      SizedBox(height: 24.h),
                                                      // Premium text with gradient
                                                      ShaderMask(
                                                        shaderCallback: (bounds) {
                                                          return LinearGradient(
                                                            colors: [
                                                              Colors.amber,
                                                              Colors.orange,
                                                              Colors.amber,
                                                            ],
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                          ).createShader(
                                                            bounds,
                                                          );
                                                        },
                                                        child: Text(
                                                          'Premium Content',
                                                          style: TextStyle(
                                                            fontSize: 24.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),

                                                      SizedBox(height: 16.h),
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24.w,
                                                            ),
                                                        child: Text(
                                                          'Subscribe to unlock this exclusive content and more!',
                                                          style: TextStyle(
                                                            color: isDarkMode
                                                                ? Colors
                                                                      .grey[300]
                                                                : Colors
                                                                      .grey[700],
                                                            fontSize: 16.sp,
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),

                                                      SizedBox(height: 24.h),
                                                      // Premium button
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  Colors.amber,
                                                                  Colors.orange,
                                                                ],
                                                                begin: Alignment
                                                                    .topLeft,
                                                                end: Alignment
                                                                    .bottomRight,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16.r,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .amber
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 8.r,
                                                              spreadRadius: 0,
                                                              offset: Offset(
                                                                0,
                                                                2.h,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pushNamed(
                                                              context,
                                                              RoutesName
                                                                  .subscriptionScreen,
                                                            );
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            foregroundColor:
                                                                Colors.white,
                                                            shadowColor: Colors
                                                                .transparent,
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      32.w,
                                                                  vertical:
                                                                      14.h,
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16.r,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Subscribe Now',
                                                            style: TextStyle(
                                                              fontSize: 16.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Action buttons - Now in their own container below the content
                                      // This ensures they're touchable while still moving with the card
                                      // Action buttons - Now in their own container below the content
                                      if (!(tip.isPremium && !canAccessPremium))
                                        Container(
                                          margin: EdgeInsets.only(top: 16.h),
                                          height: 60.h,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Favorite button with Showcase
                                              index == _currentIndex
                                                  ? Showcase(
                                                      key:
                                                          _favoriteButtonShowcaseKey,
                                                      title: 'Like',
                                                      description:
                                                          'Add this tip to your favorites for easy access later',
                                                      tooltipBackgroundColor:
                                                          isDarkMode
                                                          ? AppColors
                                                                .darkSurface
                                                          : AppColors
                                                                .lightSurface,
                                                      textColor: isDarkMode
                                                          ? AppColors
                                                                .darkTextPrimary
                                                          : AppColors
                                                                .lightTextPrimary,
                                                      overlayColor: isDarkMode
                                                          ? AppColors.overlay
                                                          : Colors
                                                                .grey
                                                                .shade200,
                                                      titleTextStyle: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                      ),
                                                      descTextStyle: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 14.sp,
                                                        color: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                      ),
                                                      tooltipPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 8.h,
                                                          ),
                                                      targetPadding:
                                                          EdgeInsets.all(8.w),
                                                      targetShapeBorder:
                                                          const CircleBorder(),
                                                      child: _buildActionButton(
                                                        isTipFavorite,
                                                        isDarkMode,
                                                        () {
                                                          if (index ==
                                                              _currentIndex) {
                                                            _toggleFavorite();
                                                          }
                                                        },
                                                      ),
                                                    )
                                                  : _buildActionButton(
                                                      isTipFavorite,
                                                      isDarkMode,
                                                      () {
                                                        if (index ==
                                                            _currentIndex) {
                                                          _toggleFavorite();
                                                        }
                                                      },
                                                    ),

                                              // Share button with Showcase
                                              index == _currentIndex
                                                  ? Showcase(
                                                      key:
                                                          _shareButtonShowcaseKey,
                                                      title: 'Share',
                                                      description:
                                                          'Share this tip with friends and family',
                                                      tooltipBackgroundColor:
                                                          isDarkMode
                                                          ? AppColors
                                                                .darkSurface
                                                          : AppColors
                                                                .lightSurface,
                                                      textColor: isDarkMode
                                                          ? AppColors
                                                                .darkTextPrimary
                                                          : AppColors
                                                                .lightTextPrimary,
                                                      overlayColor: isDarkMode
                                                          ? AppColors.overlay
                                                          : Colors
                                                                .grey
                                                                .shade200,
                                                      titleTextStyle: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                      ),
                                                      descTextStyle: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 14.sp,
                                                        color: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                      ),
                                                      tooltipPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 8.h,
                                                          ),
                                                      targetPadding:
                                                          EdgeInsets.all(8.w),
                                                      targetShapeBorder:
                                                          const CircleBorder(),
                                                      child: _buildShareButton(
                                                        isDarkMode,
                                                        tip,
                                                      ),
                                                    )
                                                  : _buildShareButton(
                                                      isDarkMode,
                                                      tip,
                                                    ),

                                              // Slideshow button with Showcase (only if slideshow is enabled)
                                              if (settingsProvider
                                                  .slideshowEnabled)
                                                index == _currentIndex
                                                    ? Showcase(
                                                        key:
                                                            _slideshowButtonShowcaseKey,
                                                        title: 'Slideshow',
                                                        description:
                                                            'Enable slideshow mode to automatically view all tips',
                                                        tooltipBackgroundColor:
                                                            isDarkMode
                                                            ? AppColors
                                                                  .darkSurface
                                                            : AppColors
                                                                  .lightSurface,
                                                        textColor: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                        overlayColor: isDarkMode
                                                            ? AppColors.overlay
                                                            : Colors
                                                                  .grey
                                                                  .shade200,
                                                        titleTextStyle: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDarkMode
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                        descTextStyle: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 14.sp,
                                                          color: isDarkMode
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                        tooltipPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12.w,
                                                              vertical: 8.h,
                                                            ),
                                                        targetPadding:
                                                            EdgeInsets.all(8.w),
                                                        targetShapeBorder:
                                                            const CircleBorder(),
                                                        child:
                                                            _buildSlideshowButton(
                                                              isDarkMode,
                                                            ),
                                                      )
                                                    : _buildSlideshowButton(
                                                        isDarkMode,
                                                      ),

                                              // Fullscreen button with Showcase
                                              if (settingsProvider
                                                  .showFullScreenIcon)
                                                index == _currentIndex
                                                    ? Showcase(
                                                        key:
                                                            _fullscreenButtonShowcaseKey,
                                                        title: 'Fullscreen',
                                                        description:
                                                            'Toggle fullscreen mode for better viewing experience',
                                                        tooltipBackgroundColor:
                                                            isDarkMode
                                                            ? AppColors
                                                                  .darkSurface
                                                            : AppColors
                                                                  .lightSurface,
                                                        textColor: isDarkMode
                                                            ? AppColors
                                                                  .darkTextPrimary
                                                            : AppColors
                                                                  .lightTextPrimary,
                                                        overlayColor: isDarkMode
                                                            ? AppColors.overlay
                                                            : Colors
                                                                  .grey
                                                                  .shade200,
                                                        titleTextStyle: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDarkMode
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                        descTextStyle: TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 14.sp,
                                                          color: isDarkMode
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                        ),
                                                        tooltipPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12.w,
                                                              vertical: 8.h,
                                                            ),
                                                        targetPadding:
                                                            EdgeInsets.all(8.w),
                                                        targetShapeBorder:
                                                            const CircleBorder(),
                                                        child:
                                                            _buildFullscreenButton(
                                                              isDarkMode,
                                                            ),
                                                      )
                                                    : _buildFullscreenButton(
                                                        isDarkMode,
                                                      ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Heart animations
                          for (final heart in _hearts)
                            Positioned(
                              bottom: 100.h,
                              left: heart.xOffset,
                              child: HeartWidget(
                                animation: _heartAnimationController,
                                size: heart.size,
                              ),
                            ),

                          // Swipe hint if needed
                          if (_showSwipeHint)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 80.h,
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _swipeAnimationController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _swipeAnimation.value),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.keyboard_arrow_up,
                                            color: isDarkMode
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.black.withOpacity(0.7),
                                            size: 36.sp,
                                          ),
                                          SizedBox(height: 8.h),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 8.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Colors.black.withOpacity(
                                                      0.7,
                                                    )
                                                  : Colors.white.withOpacity(
                                                      0.8,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(16.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'Swipe up for next tip',
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black.withOpacity(
                                                        0.8,
                                                      ),
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
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

  // Helper methods for buttons with glassmorphic design
  Widget _buildActionButton(
    bool isFavorite,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.25),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25.r),
              onTap: onTap,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? Colors.red
                    : isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                size: 26.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(bool isDarkMode, TipModel tip) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.25),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25.r),
              onTap: () =>
                  Share.share('${tip.tipsTitle}\n${tip.tipsDescription}'),
              child: Icon(
                Icons.share,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                size: 26.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideshowButton(bool isDarkMode) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Return an empty widget if slideshow is disabled
    if (!settingsProvider.slideshowEnabled) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isSlideshowEnabled
                ? (isDarkMode
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.3))
                : (isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2)),
            border: Border.all(
              color: _isSlideshowEnabled
                  ? AppColors.primary.withOpacity(0.5)
                  : (isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.25)),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: _isSlideshowEnabled
                    ? AppColors.primary.withOpacity(0.2)
                    : (isDarkMode
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05)),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25.r),
                  onTap: _toggleSlideshow,
                  child: Icon(
                    _isSlideshowEnabled ? Icons.pause : Icons.play_arrow,
                    color: _isSlideshowEnabled
                        ? Colors.white
                        : (isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    size: 26.sp,
                  ),
                ),
              ),
              if (_isSlideshowEnabled)
                Positioned(
                  bottom: 5.h,
                  child: Text(
                    '$_countdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenButton(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isFullScreen
                ? (isDarkMode
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.3))
                : (isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2)),
            border: Border.all(
              color: _isFullScreen
                  ? AppColors.primary.withOpacity(0.5)
                  : (isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.25)),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFullScreen
                    ? AppColors.primary.withOpacity(0.2)
                    : (isDarkMode
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05)),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25.r),
              onTap: _toggleFullScreen,
              child: Icon(
                _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: _isFullScreen
                    ? Colors.white
                    : (isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                size: 26.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
