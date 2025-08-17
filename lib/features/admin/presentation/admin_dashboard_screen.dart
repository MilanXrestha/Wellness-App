import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/common/widgets/custom_alert_dialog.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import '../../../core/providers/theme_provider.dart';
import 'manage_users_screen.dart';
import 'manage_categories_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _stats = {
    'Total Users': '0',
    'Total Subscribed Users': '0',
    'Total Preferences': '0',
    'Total Categories': '0',
    'Total Tips': '0',
    'Tips by Type': 'Quotes: 0, Tips: 0, Health Tips: 0',
    'Total Earnings': '0.00',
  };
  List<String> _allUserIds = [];
  List<Map<String, dynamic>> _transactions = [];
  String _selectedSortOption = 'Weekly'; // Default sort option
  final List<String> _sortOptions = ['Today', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestore.collection('users').where('userRole', isNotEqualTo: 'admin').get(),
        _firestore.collection('subscriptions').where('status', isEqualTo: 'active').get(),
        _firestore.collection('preferences').get(),
        _firestore.collection('categories').get(),
        _firestore.collection('tips').get(),
        _firestore.collection('tips').where('tipsType', isEqualTo: 'quote').get(),
        _firestore.collection('tips').where('tipsType', isEqualTo: 'tip').get(),
        _firestore.collection('tips').where('tipsType', isEqualTo: 'healthTips').get(),
        _firestore.collection('transactions').where('status', isEqualTo: 'completed').get(),
      ]);

      double totalEarnings = 0.0;
      List<Map<String, dynamic>> transactions = [];
      for (var doc in results[8].docs) {
        final data = doc.data();
        final amount = data['amount'];
        final createdAt = data['createdAt'] as Timestamp?;
        if (amount != null && amount is num && createdAt != null) {
          totalEarnings += amount.toDouble();
          transactions.add({
            'amount': amount.toDouble(),
            'timestamp': createdAt.toDate(),
          });
        }
      }

      if (mounted) {
        setState(() {
          _allUserIds = results[0].docs.map((doc) => doc.id).toList();
          _stats = {
            'Total Users': results[0].size.toString(),
            'Total Subscribed Users': results[1].size.toString(),
            'Total Preferences': results[2].size.toString(),
            'Total Categories': results[3].size.toString(),
            'Total Tips': results[4].size.toString(),
            'Tips by Type': 'Quotes: ${results[5].size}, Tips: ${results[6].size}, Health Tips: ${results[7].size}',
            'Total Earnings': totalEarnings.toStringAsFixed(2),
          };
          _transactions = transactions;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: '${AppStrings.error} ${e.toString().replaceFirst('Exception: ', '')}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signOut();
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: AppStrings.signOutSuccess,
          isSuccess: true,
          onOkPressed: () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: '${AppStrings.error} ${e.toString().replaceFirst('Exception: ', '')}',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showSignOutDialog() async {
    return CustomAlertDialog.show(
      context: context,
      title: AppStrings.signOut,
      message: AppStrings.signOutConfirmation,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.signOut,
      onConfirm: () {},
    );
  }

  void _showProfileMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100.w, 60.h, 10.w, 0),
      items: [
        PopupMenuItem(
          value: 'sign_out',
          child: Text(
            AppStrings.signOut,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    ).then((value) {
      if (value == 'sign_out' && mounted) {
        _showSignOutDialog().then((shouldSignOut) {
          if (shouldSignOut == true) {
            _handleSignOut();
          }
        });
      } else if (value == 'settings' && mounted) {
        Navigator.pushNamed(context, RoutesName.userPrefsScreen);
      }
    });
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
    required int index,
    required bool isDarkMode,
  }) {
    return FadeInUp(
      duration: Duration(milliseconds: 400 + (index * 100)),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [AppColors.darkSurface, AppColors.darkSurface.withOpacity(0.8)]
                  : [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        icon,
                        size: 24.sp,
                        color: accentColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                        color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getEarningsSpots(String sortOption) {
    final now = DateTime.now();
    List<Map<String, dynamic>> filteredTransactions = [];

    if (sortOption == 'Today') {
      filteredTransactions = _transactions.where((t) {
        final date = t['timestamp'] as DateTime;
        return date.year == now.year && date.month == now.month && date.day == now.day;
      }).toList();
      final Map<int, double> hourlyData = {};
      for (var t in filteredTransactions) {
        final hour = (t['timestamp'] as DateTime).hour;
        hourlyData[hour] = (hourlyData[hour] ?? 0.0) + t['amount'];
      }
      return List.generate(24, (index) {
        return FlSpot(index.toDouble(), hourlyData[index] ?? 0.0);
      });
    } else if (sortOption == 'Weekly') {
      final startDate = now.subtract(const Duration(days: 6));
      filteredTransactions = _transactions.where((t) {
        final date = t['timestamp'] as DateTime;
        return date.isAfter(startDate.subtract(const Duration(days: 1)));
      }).toList();
      final Map<int, double> dailyData = {};
      for (var t in filteredTransactions) {
        final date = t['timestamp'] as DateTime;
        final daysDiff = date.difference(startDate).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          dailyData[daysDiff] = (dailyData[daysDiff] ?? 0.0) + t['amount'];
        }
      }
      return List.generate(7, (index) {
        return FlSpot(index.toDouble(), dailyData[index] ?? 0.0);
      });
    } else {
      final startDate = now.subtract(const Duration(days: 29));
      filteredTransactions = _transactions.where((t) {
        final date = t['timestamp'] as DateTime;
        return date.isAfter(startDate.subtract(const Duration(days: 1)));
      }).toList();
      final Map<int, double> dailyData = {};
      for (var t in filteredTransactions) {
        final date = t['timestamp'] as DateTime;
        final daysDiff = date.difference(startDate).inDays;
        if (daysDiff >= 0 && daysDiff < 30) {
          dailyData[daysDiff] = (dailyData[daysDiff] ?? 0.0) + t['amount'];
        }
      }
      return List.generate(30, (index) {
        return FlSpot(index.toDouble(), dailyData[index] ?? 0.0);
      });
    }
  }

  Widget earningsChart({required bool isDarkMode}) {
    final spots = _getEarningsSpots(_selectedSortOption);
    final maxY = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2
        : 100.0;
    final interval = maxY > 0 ? maxY / 4 : 25.0;

    return FadeInUp(
      duration: const Duration(milliseconds: 900),
      child: Container(
        height: 300.h,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [AppColors.darkSurface, AppColors.darkSurface.withOpacity(0.8)]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Earnings',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSortOption,
                      isDense: true,
                      items: _sortOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(
                            option,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && mounted) {
                          setState(() {
                            _selectedSortOption = value;
                          });
                        }
                      },
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                        size: 20.sp,
                      ),
                      dropdownColor: isDarkMode ? AppColors.darkSurface : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Revenue (${_selectedSortOption.toLowerCase()})',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: spots.isEmpty || spots.every((spot) => spot.y == 0)
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 48.sp,
                      color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No transactions for ${_selectedSortOption.toLowerCase()}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.sp,
                        color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
                  : LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                      barWidth: 4.w,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 6.r,
                          color: AppColors.primary,
                          strokeWidth: 2.w,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        reservedSize: 40.w,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.sp,
                              color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _selectedSortOption == 'Today' ? 4 : _selectedSortOption == 'Weekly' ? 1 : 5,
                        getTitlesWidget: (value, meta) {
                          if (_selectedSortOption == 'Today') {
                            if (value.toInt() % 4 == 0) {
                              return Text(
                                '${value.toInt()}h',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.sp,
                                  color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          } else if (_selectedSortOption == 'Weekly') {
                            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                            return Text(
                              days[date.weekday - 1],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.sp,
                                color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                              ),
                            );
                          } else {
                            if (value.toInt() % 5 == 0) {
                              final date = DateTime.now().subtract(Duration(days: 29 - value.toInt()));
                              return Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.sp,
                                  color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tipsChart({required bool isDarkMode}) {
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        height: 300.h,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [AppColors.darkSurface, AppColors.darkSurface.withOpacity(0.8)]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Distribution',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Overview of content types',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: double.parse(_stats['Total Tips']!) == 0
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 48.sp,
                      color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No tips available',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.sp,
                        color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
                  : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: double.parse(_stats['Total Tips']!) * 1.2,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: double.parse(_stats['Tips by Type']!.split(', ')[0].split(': ')[1]),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.accentBlue,
                              AppColors.accentBlue.withOpacity(0.7),
                            ],
                          ),
                          width: 40.w,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8.r),
                            topRight: Radius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: double.parse(_stats['Tips by Type']!.split(', ')[1].split(': ')[1]),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                          ),
                          width: 40.w,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8.r),
                            topRight: Radius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: double.parse(_stats['Tips by Type']!.split(', ')[2].split(': ')[1]),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.error,
                              AppColors.error.withOpacity(0.7),
                            ],
                          ),
                          width: 40.w,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8.r),
                            topRight: Radius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Quotes', 'Tips', 'Health'];
                          return Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              titles[value.toInt()],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: double.parse(_stats['Total Tips']!) > 0
                        ? double.parse(_stats['Total Tips']!) * 0.3
                        : 1.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final currentUser = FirebaseAuth.instance.currentUser;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldSignOut = await _showSignOutDialog();
        if (shouldSignOut == true) {
          await _handleSignOut();
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.grey.shade50,
        body: Stack(
          children: [
            Container(
              height: 250.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [AppColors.darkSurface.withOpacity(0.5), AppColors.darkBackground]
                      : [Colors.white, Colors.grey.shade100],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeInLeft(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white.withOpacity(0.8) : AppColors.lightTextPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              FadeInLeft(
                                duration: const Duration(milliseconds: 600),
                                child: Text(
                                  currentUser?.displayName ?? 'Admin',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FadeInRight(
                          duration: const Duration(milliseconds: 500),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: IconButton(
                                  icon: FaIcon(
                                    isDarkMode ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
                                    size: 20.sp,
                                    color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                  onPressed: () {
                                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(!isDarkMode);
                                  },
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: _showProfileMenu,
                                child: Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors:  isDarkMode
                                      ?[
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.7),
                                      ]
                                      :[
                                        AppColors.lightSurface,
                                        AppColors.lightSurface,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.5),
                                      width: 2.w,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDarkMode ? AppColors.darkBackground : Colors.white,
                                    ),
                                    child: CircleAvatar(
                                      radius: 24.r,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty
                                          ? NetworkImage(currentUser.photoURL!)
                                          : null,
                                      child: currentUser?.photoURL == null || currentUser!.photoURL!.isEmpty
                                          ? Text(
                                        currentUser?.displayName?.isNotEmpty == true
                                            ? currentUser!.displayName![0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.0,
                      children: [
                        statCard(
                          title: 'Total Users',
                          value: _stats['Total Users']!,
                          icon: FontAwesomeIcons.users,
                          accentColor: AppColors.accentBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const ManageUsersScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 400),
                              ),
                            );
                          },
                          index: 0,
                          isDarkMode: isDarkMode,
                        ),
                        statCard(
                          title: 'Subscribed',
                          value: _stats['Total Subscribed Users']!,
                          icon: FontAwesomeIcons.crown,
                          accentColor: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, RoutesName.manageSubscriptionScreen),
                          index: 1,
                          isDarkMode: isDarkMode,
                        ),
                        statCard(
                          title: 'Total Tips',
                          value: _stats['Total Tips']!,
                          icon: FontAwesomeIcons.lightbulb,
                          accentColor: Colors.orange,
                          onTap: () => Navigator.pushNamed(context, RoutesName.manageTipsScreen),
                          index: 2,
                          isDarkMode: isDarkMode,
                        ),
                        statCard(
                          title: 'Categories',
                          value: _stats['Total Categories']!,
                          icon: FontAwesomeIcons.folderOpen,
                          accentColor: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const ManageCategoriesScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 400),
                              ),
                            );
                          },
                          index: 3,
                          isDarkMode: isDarkMode,
                        ),
                        statCard(
                          title: 'Preferences',
                          value: _stats['Total Preferences']!,
                          icon: FontAwesomeIcons.heart,
                          accentColor: Colors.red,
                          onTap: () => Navigator.pushNamed(context, RoutesName.managePreferenceScreen),
                          index: 4,
                          isDarkMode: isDarkMode,
                        ),
                        statCard(
                          title: 'Earnings',
                          value: 'Rs. ${_stats['Total Earnings']}',
                          icon: FontAwesomeIcons.dollarSign,
                          accentColor: AppColors.primary,
                          onTap: () {},
                          index: 5,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    FadeInLeft(
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        'Overview',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 24.sp,
                          color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    earningsChart(isDarkMode: isDarkMode),
                    SizedBox(height: 20.h),
                    tipsChart(isDarkMode: isDarkMode),
                    SizedBox(height: 20.h),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RoutesName.sendNotificationScreen,
                            arguments: _allUserIds,
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDarkMode
                                  ? [AppColors.darkSurface, AppColors.darkSurface.withOpacity(0.8)]
                                  : [Colors.white, Colors.grey.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              width: 1.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                                blurRadius: 8.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RoutesName.sendNotificationScreen,
                                  arguments: _allUserIds,
                                );
                              },
                              borderRadius: BorderRadius.circular(16.r),
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16.w),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primary.withOpacity(0.7),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: FaIcon(
                                        FontAwesomeIcons.solidPaperPlane,
                                        size: 24.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 20.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Send Notifications',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.w700,
                                              color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Notify all ${_stats['Total Users']} users',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode ? Colors.white.withOpacity(0.6) : AppColors.lightTextSecondary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
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
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20.r,
                            offset: Offset(0, 10.h),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3.w,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
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