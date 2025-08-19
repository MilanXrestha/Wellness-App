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
  late List<Widget> _screens;
  String? _userId;
  bool _isNavBarVisible = true;
  bool _isSearchActive = false;

  void _setNavBarVisibility(bool isVisible) {
    setState(() {
      _isSearchActive = !isVisible; // Track search state
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

    _navBarOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 2.0)).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _screens = [
      UserDashboardScreen(
        onViewAllCategories: _onViewAllCategories,
      ),
      ExploreScreen(
        onSearchActiveChanged: _setNavBarVisibility,
      ),
      CategoryScreen(
        selectedCategory: _selectedCategory,
        onSearchActiveChanged: _setNavBarVisibility,
      ),
      FavoriteScreen(
        onSearchActiveChanged: _setNavBarVisibility,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        _selectedCategory = null;
        _screens[2] = CategoryScreen(
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
    setState(() {
      _selectedIndex = 2;
      _selectedCategory = null;
      _screens[2] = CategoryScreen(
        selectedCategory: _selectedCategory,
        onSearchActiveChanged: _setNavBarVisibility,
      );
      _isNavBarVisible = true;
      _isSearchActive = false;
      _animationController.reverse();
    });
    log('Navigated to Category tab via View All', name: 'MainScreen');
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _isNavBarVisible = true;
        _isSearchActive = false;
        _animationController.reverse();
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

  // Handle scroll notifications to show/hide nav bar
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isSearchActive) {
      // Ignore scroll events when search is active
      return false;
    }

    if (notification is UserScrollNotification) {
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
    return false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { // Corrected parameter type from Context to BuildContext
    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      });
      return const Center(child: CircularProgressIndicator());
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 14.h,
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
    );
  }
}