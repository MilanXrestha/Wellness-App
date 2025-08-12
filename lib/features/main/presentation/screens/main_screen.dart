import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/categories/presentation/screens/category_screen.dart';
import 'package:wellness_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:wellness_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:wellness_app/features/favorites/presentation/screens/favorite_screen.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import 'package:wellness_app/common/widgets/custom_bottom_nav_bar.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'dart:developer';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  CategoryModel? _selectedCategory;
  late AnimationController _animationController;
  late Animation<Offset> _navBarOffset;
  late ScrollController _scrollController;
  bool _isNavBarVisible = true;
  String? _userId;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _userId = authService.getCurrentUser()?.uid;

    _screens = [
      UserDashboardScreen(
        onViewAllCategories: _onViewAllCategories,
      ),
      const ExploreScreen(),
      CategoryScreen(selectedCategory: _selectedCategory),
      const FavoriteScreen(),
    ];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _navBarOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 2.0)).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isNavBarVisible) {
        _animationController.forward();
        _isNavBarVisible = false;
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isNavBarVisible) {
        _animationController.reverse();
        _isNavBarVisible = true;
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        _selectedCategory = null;
        _screens[2] = CategoryScreen(selectedCategory: _selectedCategory);
      }
      if (!_isNavBarVisible) {
        _animationController.reverse();
        _isNavBarVisible = true;
      }
    });
    log('Tab switched to index: $index', name: 'MainScreen');
  }

  void _onViewAllCategories() {
    setState(() {
      _selectedIndex = 2;
      _selectedCategory = null;
      _screens[2] = CategoryScreen(selectedCategory: _selectedCategory);
      if (!_isNavBarVisible) {
        _animationController.reverse();
        _isNavBarVisible = true;
      }
    });
    log('Navigated to Category tab via View All', name: 'MainScreen');
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        if (!_isNavBarVisible) {
          _animationController.reverse();
          _isNavBarVisible = true;
        }
      });
      return false;
    } else {
      final bool shouldExit = await CustomAlertDialog.show(
        context: context,
        title: 'Exit App',
        message: 'Do you really want to exit the app?',
        confirmText: 'Exit',
        cancelText: 'Cancel',
      );
      if (shouldExit) {
        SystemNavigator.pop();
      }
      return false;
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, RoutesName.profileScreen).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      });
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _screens.asMap().entries.map((entry) => _wrapWithScrollController(entry.value, entry.key)).toList(),
            ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 14.h,
              child: SlideTransition(
                position: _navBarOffset,
                child: CustomBottomNavBar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithScrollController(Widget screen, int index) {
    if (index == 0 && screen is UserDashboardScreen) {
      return NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            _handleScroll();
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: screen,
        ),
      );
    }
    return screen;
  }
}