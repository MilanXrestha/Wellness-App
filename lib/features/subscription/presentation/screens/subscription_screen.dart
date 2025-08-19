import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';
import 'package:wellness_app/features/subscription/data/models/transaction_model.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/services/data_repository.dart';
import '../providers/premium_status_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final AuthService _authService = AuthService();
  final DataRepository _dataRepository = DataRepository.instance;
  bool _isSubscribing = false;
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(1); // Default to "3 Months"

  final List<Map<String, dynamic>> _plans = [
    {
      'planId': 'GOLD',
      'name': 'Monthly',
      'price': 50.0,
      'duration': '1 month',
      'tier': 1,
      'benefits': [
        'Access to all premium tips and quotes',
        'Priority notifications',
        'Monthly exclusive content',
      ],
    },
    {
      'planId': 'PLATINUM',
      'name': '3 Months',
      'price': 135.0,
      'duration': '3 months',
      'tier': 2,
      'benefits': [
        'All monthly benefits',
        '10% savings compared to monthly',
        'Early access to new features',
      ],
      'recommended': true,
    },
    {
      'planId': 'DIAMOND',
      'name': 'Annual',
      'price': 480.0,
      'duration': '12 months',
      'tier': 3,
      'benefits': [
        'All quarterly benefits',
        '20% savings compared to monthly',
        'Annual exclusive wellness guide',
      ],
    },
  ];

  // eSewa test credentials
  static const String _clientId = 'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R';
  static const String _secretKey = 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==';

  int _getPlanTier(String planId) {
    return _plans.firstWhere((p) => p['planId'] == planId)['tier'] as int;
  }

  double _getUpgradeSavings(String currentPlanId, String newPlanId) {
    if (currentPlanId == 'GOLD' && newPlanId == 'PLATINUM') return 10.0;
    if (currentPlanId == 'GOLD' && newPlanId == 'DIAMOND') return 20.0;
    if (currentPlanId == 'PLATINUM' && newPlanId == 'DIAMOND') return 10.0;
    return 0.0;
  }


  Future<void> _subscribeToPlan(Map<String, dynamic> plan) async {
    if (_isSubscribing) return;

    setState(() => _isSubscribing = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw Exception('No authenticated user found');

      final productId = 'plan_${plan['planId']}_${DateTime.now().millisecondsSinceEpoch}';
      final productName = '${plan['name']} Subscription';
      final amount = plan['price'].toString();

      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test,
          clientId: _clientId,
          secretId: _secretKey,
        ),
        esewaPayment: EsewaPayment(
          productId: productId,
          productName: productName,
          productPrice: amount,
          callbackUrl: '',
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult result) async {
          debugPrint(":::SUCCESS::: => $result");
          await _verifyAndSaveTransaction(plan, result, user.uid);
        },
        onPaymentFailure: (result) {
          if (mounted) {
            setState(() => _isSubscribing = false);
            CustomBottomSheet.show(
              context: context,
              message: 'Payment failed: $result',
              isSuccess: false,
            );
          }
        },
        onPaymentCancellation: (result) {
          if (mounted) {
            setState(() => _isSubscribing = false);
            CustomBottomSheet.show(
              context: context,
              message: 'Payment cancelled: $result',
              isSuccess: false,
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubscribing = false);
        CustomBottomSheet.show(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _verifyAndSaveTransaction(
      Map<String, dynamic> plan,
      EsewaPaymentSuccessResult result,
      String userId,
      ) async {
    try {
      const isTestMode = true;
      if (!isTestMode) {
        final response = await http.get(
          Uri.parse(
            'https://rc.esewa.com.np/api/epay/transaction/status/?product_code=EPAYTEST&total_amount=${result.totalAmount}&transaction_uuid=${result.productId}',
          ),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] != 'COMPLETE') {
            throw Exception(
              'Transaction verification failed: ${data['error_message'] ?? 'Unknown error'}',
            );
          }
        } else {
          throw Exception('Transaction verification API failed: ${response.statusCode}');
        }
      }

      final now = DateTime.now();
      final duration = plan['duration'] as String;
      DateTime? endDate;
      if (duration == '1 month') {
        endDate = now.add(const Duration(days: 30));
      } else if (duration == '3 months') {
        endDate = now.add(const Duration(days: 90));
      } else if (duration == '12 months') {
        endDate = now.add(const Duration(days: 365));
      }

      final subscription = SubscriptionModel(
        userId: userId,
        planId: plan['planId'] as String,
        status: 'active',
        startDate: now,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
        paymentMethod: 'esewa',
        lastTransactionId: result.refId,
        isAutoRenew: true,
      );

      final transaction = TransactionModel(
        id: result.refId,
        userId: userId,
        subscriptionId: userId,
        paymentProviderTransactionId: result.refId,
        paymentProvider: 'esewa',
        amount: double.parse(result.totalAmount),
        currency: 'NPR',
        status: 'completed',
        planId: plan['planId'] as String,
        createdAt: now,
      );

      await _dataRepository.updateSubscription(subscription);
      await _dataRepository.addTransaction(transaction);

      await Provider.of<PremiumStatusProvider>(context, listen: false).updatePremiumStatus();

      if (mounted) {
        setState(() => _isSubscribing = false);
        CustomBottomSheet.show(
          context: context,
          message: 'Subscription activated successfully! You now have premium access.',
          isSuccess: true,
          onOkPressed: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubscribing = false);
        CustomBottomSheet.show(
          context: context,
          message: 'Failed to process subscription: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _showCancelConfirmation(String userId) async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Subscription',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your subscription?',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontFamily: 'Poppins',
            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                fontFamily: 'Poppins',
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelSubscription(userId);
    }
  }

  Future<void> _cancelSubscription(String userId) async {
    if (_isSubscribing) return;

    setState(() => _isSubscribing = true);

    try {
      final subscription = await _dataRepository.getSubscription(userId);
      if (subscription == null) {
        throw Exception('No active subscription found');
      }

      final updatedSubscription = SubscriptionModel(
        userId: subscription.userId,
        planId: subscription.planId,
        status: 'cancelled',
        startDate: subscription.startDate,
        endDate: subscription.endDate,
        createdAt: subscription.createdAt,
        updatedAt: DateTime.now(),
        paymentMethod: subscription.paymentMethod,
        lastTransactionId: subscription.lastTransactionId,
        isAutoRenew: false,
      );

      await _dataRepository.updateSubscription(updatedSubscription);

      await Provider.of<PremiumStatusProvider>(context, listen: false).updatePremiumStatus();

      if (mounted) {
        setState(() => _isSubscribing = false);
        CustomBottomSheet.show(
          context: context,
          message: 'Sorry to see you go! Your subscription has been cancelled.',
          isSuccess: true,
          onOkPressed: () => setState(() {}),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubscribing = false);
        CustomBottomSheet.show(
          context: context,
          message: 'Failed to cancel subscription: $e',
          isSuccess: false,
        );
      }
    }
  }

  Widget _buildPlanCard(
      Map<String, dynamic> plan,
      ThemeData theme,
      bool isDarkMode,
      bool isActive,
      String? currentPlanId,
      bool isSubscriptionActive,
      ) {
    final isCurrentPlan = isSubscriptionActive && plan['planId'] == currentPlanId;
    final isUpgrade = currentPlanId != null && isSubscriptionActive && _getPlanTier(plan['planId']) > _getPlanTier(currentPlanId);
    final savings = isUpgrade ? _getUpgradeSavings(currentPlanId, plan['planId']) : 0.0;
    final buttonText = isCurrentPlan ? 'Current Plan' : (isUpgrade ? 'Upgrade Now' : 'Subscribe Now');
    final buttonEnabled = !isCurrentPlan;

    final borderColor = isDarkMode
        ? AppColors.primary
        : AppColors.lightTextPrimary;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Transform.scale(
        scale: isActive ? 1.05 : 0.95,
        child: Container(
          width: 280.w,
          height: 320.h,
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
              color: borderColor,
              width: isActive ? 2.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? AppColors.shadow.withOpacity(0.5) : AppColors.lightTextPrimary.withOpacity(0.2),
                blurRadius: isActive ? 10.r : 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          padding: EdgeInsets.all(12.w),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['name'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'NPR ${plan['price'].toStringAsFixed(2)} / ${plan['duration']}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (savings > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Save $savings% by upgrading!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  SizedBox(height: 25.h),
                  ...plan['benefits'].map<Widget>(
                        (benefit) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              benefit,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: buttonEnabled && !_isSubscribing ? () => _subscribeToPlan(plan) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300)
                          : (isDarkMode ? AppColors.primary : AppColors.lightTextPrimary),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                      shadowColor: isDarkMode ? null : Colors.grey.shade300,
                    ),
                    child: Text(
                      buttonText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              if (plan['recommended'] == true && !isCurrentPlan)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12.r),
                        topRight: Radius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Best Value',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final userId = _authService.getCurrentUser()?.uid ?? '';

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: false,
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 64.h,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
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
                                  'Go Premium',
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
                                Icons.history,
                                size: 24.sp,
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, RoutesName.transactionHistoryScreen);
                              },
                              tooltip: 'Transaction History',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                    child: FutureBuilder<SubscriptionModel?>(
                      future: _dataRepository.getSubscription(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 4.w,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading subscription',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                                fontSize: 16.sp,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        }

                        final subscription = snapshot.data;
                        final isSubscriptionActive = subscription != null && subscription.status == 'active';
                        final currentPlanId = isSubscriptionActive ? subscription.planId : null;
                        // Set tier to 0 if no active subscription
                        final currentTier = isSubscriptionActive
                            ? _getPlanTier(currentPlanId!)
                            : 0;

                        // Show all plans if no active subscription
                        final visiblePlans = isSubscriptionActive
                            ? _plans.where((p) => _getPlanTier(p['planId']) >= currentTier).toList()
                            : List.from(_plans); // Show all plans when no active subscription

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                isSubscriptionActive ? 'Your Subscription' : 'Unlock All Premium Content',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            if (!isSubscriptionActive)
                              FadeInDown(
                                duration: const Duration(milliseconds: 800),
                                child: Text(
                                  'Choose a plan to access exclusive tips, quotes, and more!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontSize: 16.sp,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            SizedBox(height: 16.h),
                            if (subscription != null) ...[
                              FadeInUp(
                                duration: const Duration(milliseconds: 600),
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  margin: EdgeInsets.only(bottom: 16.h),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isSubscriptionActive ? 'Current Plan' : 'Subscription Details',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        '${subscription.planId.toUpperCase()} Plan • ${subscription.status.toUpperCase()}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          fontSize: 16.sp,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      if (subscription.endDate != null)
                                        Text(
                                          isSubscriptionActive
                                              ? 'Ends on ${DateFormat('MMM dd, yyyy').format(subscription.endDate!)}'
                                              : 'Cancelled on ${DateFormat('MMM dd, yyyy').format(subscription.updatedAt!)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            fontSize: 14.sp,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      if (isSubscriptionActive) ...[
                                        SizedBox(height: 12.h),
                                        ElevatedButton(
                                          onPressed: _isSubscribing
                                              ? null
                                              : () => _showCancelConfirmation(userId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDarkMode ? AppColors.error : AppColors.lightTextPrimary,
                                            foregroundColor: Colors.white,
                                            minimumSize: Size(double.infinity, 48.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            elevation: 2,
                                            shadowColor: isDarkMode ? null : Colors.grey.shade300,
                                          ),
                                          child: Text(
                                            'Cancel Subscription',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 16.h),
                            SizedBox(
                              height: 420.h,
                              child: CarouselSlider.builder(
                                itemCount: visiblePlans.length,
                                options: CarouselOptions(
                                  height: 350.h,
                                  enlargeCenterPage: true,
                                  enableInfiniteScroll: false,
                                  scrollPhysics: const ClampingScrollPhysics(),
                                  viewportFraction: 0.75,
                                  enlargeFactor: 0.3,
                                  initialPage: 0,
                                  padEnds: true,
                                  onPageChanged: (index, reason) {
                                    _currentIndex.value = index;
                                  },
                                ),
                                itemBuilder: (context, index, realIndex) {
                                  final plan = visiblePlans[index];
                                  return _buildPlanCard(
                                    plan,
                                    theme,
                                    isDarkMode,
                                    _currentIndex.value == index,
                                    currentPlanId,
                                    isSubscriptionActive,
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSubscribing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4.w,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}