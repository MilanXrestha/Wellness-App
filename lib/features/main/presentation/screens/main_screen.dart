import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/categories/presentation/screens/category_screen.dart';
import 'package:wellness_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:wellness_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:wellness_app/features/favorites/presentation/screens/favorite_screen.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import 'package:wellness_app/common/widgets/custom_bottom_nav_bar.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/main/presentation/screens/tab_switch_notification.dart';
import 'package:wellness_app/features/videoPlayer/presentation/screens/short_player_screen.dart';
import 'dart:developer';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  CategoryModel? _selectedCategory;
  late AnimationController _animationController;
  late Animation<Offset> _navBarOffset;
  late List<Widget> _screens;
  String? _userId;
  bool _isNavBarVisible = true;
  bool _isSearchActive = false;
  final GlobalKey<ShortsPlayerScreenState> _shortsPlayerKey =
  GlobalKey<ShortsPlayerScreenState>();

  void _setNavBarVisibility(bool isVisible) {
    setState(() {
      _isSearchActive = !isVisible;
      _isNavBarVisible = isVisible;
      if (isVisible) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
    log('Nav bar visibility set to: $isVisible due to search', name: 'MainScreen');
  }

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _userId = authService.getCurrentUser()?.uid;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _navBarOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 2.0))
        .animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _screens = [
      UserDashboardScreen(onViewAllCategories: _onViewAllCategories),
      ExploreScreen(onSearchActiveChanged: _setNavBarVisibility),
      ShortsPlayerScreen(
        key: _shortsPlayerKey,
        categoryName: 'Shorts',
        tabActive: _selectedIndex == 2,
        onFullScreenChanged: _setNavBarVisibility,
      ),
      CategoryScreen(
        selectedCategory: _selectedCategory,
        onSearchActiveChanged: _setNavBarVisibility,
      ),
      FavoriteScreen(onSearchActiveChanged: _setNavBarVisibility),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == 2 && index != 2) {
      _shortsPlayerKey.currentState?.pauseVideo();
      log('Paused video when switching from Shorts tab', name: 'MainScreen');
    }

    setState(() {
      _selectedIndex = index;
      _screens[2] = ShortsPlayerScreen(
        key: _shortsPlayerKey,
        categoryName: 'Shorts',
        tabActive: index == 2,
        onFullScreenChanged: _setNavBarVisibility,
      );
      if (index == 3) {
        _selectedCategory = null;
        _screens[3] = CategoryScreen(
          selectedCategory: _selectedCategory,
          onSearchActiveChanged: _setNavBarVisibility,
        );
      }
      _isNavBarVisible = true;
      _isSearchActive = false;
      _animationController.reverse();
    });
    log('Tab switched to index: $index', name: 'MainScreen');
  }

  void _onViewAllCategories() {
    if (_selectedIndex == 2) {
      _shortsPlayerKey.currentState?.pauseVideo();
      log('Paused video when navigating to Category tab via View All', name: 'MainScreen');
    }

    setState(() {
      _selectedIndex = 3;
      _selectedCategory = null;
      _screens[2] = ShortsPlayerScreen(
        key: _shortsPlayerKey,
        categoryName: 'Shorts',
        tabActive: false,
        onFullScreenChanged: _setNavBarVisibility,
      );
      _screens[3] = CategoryScreen(
        selectedCategory: _selectedCategory,
        onSearchActiveChanged: _setNavBarVisibility,
      );
      _isNavBarVisible = true;
      _isSearchActive = false;
      _animationController.reverse();
    });
    log('Navigated to Category tab via View All', name: 'MainScreen');
  }

  Future<void> _handlePop(bool didPop, dynamic result) async {
    if (didPop) {
      log('Pop already handled, skipping', name: 'MainScreen');
      return;
    }

    log('Back button pressed, current tab: $_selectedIndex', name: 'MainScreen');

    // Case 1: Not on dashboard → navigate to dashboard
    if (_selectedIndex != 0) {
      if (_selectedIndex == 2) {
        _shortsPlayerKey.currentState?.pauseVideo();
        log('Paused video when navigating back to Dashboard', name: 'MainScreen');
      }
      setState(() {
        _selectedIndex = 0;
        _screens[2] = ShortsPlayerScreen(
          key: _shortsPlayerKey,
          categoryName: 'Shorts',
          tabActive: false,
          onFullScreenChanged: _setNavBarVisibility,
        );
        _isNavBarVisible = true;
        _isSearchActive = false;
        _animationController.reverse();
      });
      log('Navigated to dashboard tab', name: 'MainScreen');
      return;
    }

    // Case 2: On dashboard → show exit dialog
    log('On dashboard, showing exit dialog', name: 'MainScreen');

    final bool exitConfirmed = await CustomAlertDialog.show(
      context: context,
      title: 'Exit App',
      message: 'Do you really want to exit the app?',
      confirmText: 'Exit',
      cancelText: 'Cancel',
    );

    if (exitConfirmed) {
      log('User confirmed exit, closing app', name: 'MainScreen');
      SystemNavigator.pop();
    } else {
      log('User cancelled exit', name: 'MainScreen');
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isSearchActive || _selectedIndex == 2) {
      return false;
    }

    if (notification is UserScrollNotification) {
      // Only react to vertical scrolls
      if (notification.metrics.axis == Axis.vertical) {
        if (notification.direction == ScrollDirection.reverse && _isNavBarVisible) {
          setState(() {
            _isNavBarVisible = false;
            _animationController.forward();
          });
          log('Nav bar hidden due to downward scroll', name: 'MainScreen');
        } else if (notification.direction == ScrollDirection.forward && !_isNavBarVisible) {
          setState(() {
            _isNavBarVisible = true;
            _animationController.reverse();
          });
          log('Nav bar shown due to upward scroll', name: 'MainScreen');
        }
      }
    }
    return false;
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('Building MainScreen, userId: $_userId', name: 'MainScreen');
    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        log('No userId, redirecting to login screen', name: 'MainScreen');
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      });
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await _handlePop(didPop, result);
      },
      child: NotificationListener<TabSwitchNotification>(
        onNotification: (notification) {
          _onItemTapped(notification.tabIndex);
          return true;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: true,
          body: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: IndexedStack(index: _selectedIndex, children: _screens),
              ),
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 7.h,
                child: SlideTransition(
                  position: _navBarOffset,
                  child: Visibility(
                    visible: _isNavBarVisible,
                    child: CustomBottomNavBar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: _onItemTapped,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}