import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/profile/data/user_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';
import 'package:wellness_app/features/subscription/data/models/transaction_model.dart';

class ManageSubscriptionsScreen extends StatefulWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  State<ManageSubscriptionsScreen> createState() => _ManageSubscriptionsScreenState();
}

class _ManageSubscriptionsScreenState extends State<ManageSubscriptionsScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  bool _isLoading = false;
  String _reloadKey = DateTime.now().toIso8601String();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _triggerReload() {
    setState(() {
      _reloadKey = DateTime.now().toIso8601String();
      _selectedUserIds.clear();
    });
  }

  Future<void> _cancelSubscription(String subscriptionId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text('Are you sure you want to cancel $userName\'s subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 2,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _firestore.collection('subscriptions').doc(subscriptionId).update({
          'status': 'canceled',
          'updatedAt': Timestamp.now(),
        });
        if (!mounted) return;
        CustomBottomSheet.show(
          context: context,
          message: '$userName\'s subscription successfully canceled.',
          isSuccess: true,
        );
      } catch (e) {
        if (!mounted) return;
        CustomBottomSheet.show(
          context: context,
          message: '${AppStrings.error} $e',
          isSuccess: false,
        );
      } finally {
        _triggerReload();
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSubscriptionCard(SubscriptionModel subscription, UserModel? user, TransactionModel? transaction, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedUserIds.contains(subscription.userId);
    final isPremium = subscription.status == 'active';
    final startDate = subscription.startDate != null
        ? DateFormat('MMM d, yyyy').format(subscription.startDate!)
        : 'Unknown';
    final endDate = subscription.endDate != null
        ? DateFormat('MMM d, yyyy').format(subscription.endDate!)
        : 'Unknown';

    return FadeInUp(
      duration: Duration(milliseconds: 300 + index * 80),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedUserIds.remove(subscription.userId);
            } else {
              _selectedUserIds.add(subscription.userId);
            }
          });
        },
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkSurface.withAlpha(230), AppColors.darkSurface.withAlpha(200)]
                      : [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.primary.withAlpha(77) : Colors.grey.shade200),
                  width: isSelected ? 2.w : 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? AppColors.shadow : Colors.grey.withOpacity(0.08),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28.r,
                        backgroundColor: AppColors.primary.withAlpha(38),
                        backgroundImage: user != null && user.photoURL != null && user.photoURL!.isNotEmpty
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user == null || user.photoURL == null || user.photoURL!.isEmpty
                            ? Text(
                          user != null && user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.userName ?? 'Unknown User',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20.sp,
                                color: isDark ? AppColors.primary : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              user?.userEmail ?? 'Unknown Email',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15.sp,
                                fontFamily: 'Roboto',
                                color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: subscription.status == 'active' ? AppColors.primary.withOpacity(0.1) : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                subscription.status.capitalize(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: subscription.status == 'active' ? AppColors.primary : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Subscription Details',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                      color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan: ${subscription.planId.capitalize()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Start Date: $startDate',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'End Date: $endDate',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Auto-Renew: ${subscription.isAutoRenew ? 'Yes' : 'No'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Payment Method: ${subscription.paymentMethod.capitalize()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp,
                            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (transaction != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      'Transaction Details',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount: ${transaction.amount} ${transaction.currency}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13.sp,
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Provider: ${transaction.paymentProvider.capitalize()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13.sp,
                              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Status: ${transaction.status.capitalize()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13.sp,
                              color: transaction.status == 'completed' ? AppColors.primary : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (subscription.status == 'active')
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: AnimationController(
                                duration: Duration(milliseconds: 400 + index * 80),
                                vsync: this,
                              )..forward(),
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () => _cancelSubscription(subscription.userId, user?.userName ?? 'Unknown'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              elevation: 2,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade700, Colors.red.shade900],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.ban,
                                    size: 12.sp,
                                    color: AppColors.lightBackground,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Cancel',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: AnimationController(
                              duration: Duration(milliseconds: 400 + index * 80),
                              vsync: this,
                            )..forward(),
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.sendNotificationScreen,
                              arguments: [subscription.userId],
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withAlpha(153)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 4.r,
                                  offset: Offset(2.w, 2.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications,
                              size: 24.sp,
                              color: isDark ? AppColors.lightBackground : AppColors.lightBackground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isPremium)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: isDark ? 1.r : 4.r,
                        offset: Offset(0, isDark ? 1.h : 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 14.sp,
                        color: Colors.black87,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  floating: false,
                  snap: false,
                  title: Text(
                    'Manage Subscriptions',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                      color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20.sp,
                      color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: 22.sp,
                        color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                      ),
                      onPressed: _triggerReload,
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    color: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: isDark
                            ? []
                            : [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by user or plan',
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade600,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDark ? AppColors.darkTextPrimary : Colors.grey.shade600,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.w),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  sliver: StreamBuilder<QuerySnapshot>(
                    key: ValueKey(_reloadKey),
                    stream: _firestore.collection('subscriptions').snapshots(),
                    builder: (context, subscriptionSnapshot) {
                      if (!subscriptionSnapshot.hasData) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );
                      }

                      final subscriptions = subscriptionSnapshot.data!.docs
                          .map((doc) => SubscriptionModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                          .toList();

                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('users').snapshots(),
                        builder: (context, userSnapshot) {
                          final users = userSnapshot.hasData
                              ? userSnapshot.data!.docs
                              .map((doc) => UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                              .toList()
                              : <UserModel>[];

                          return StreamBuilder<QuerySnapshot>(
                            stream: _firestore.collection('transactions').snapshots(),
                            builder: (context, transactionSnapshot) {
                              final transactions = transactionSnapshot.hasData
                                  ? transactionSnapshot.data!.docs
                                  .map((doc) => TransactionModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                                  .toList()
                                  : <TransactionModel>[];

                              final filteredSubscriptions = subscriptions.where((sub) {
                                final user = users.firstWhereOrNull((u) => u.userId == sub.userId);
                                return user != null &&
                                    (user.userName.toLowerCase().contains(_searchQuery) ||
                                        user.userEmail.toLowerCase().contains(_searchQuery) ||
                                        sub.planId.toLowerCase().contains(_searchQuery));
                              }).toList();

                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                    if (index >= filteredSubscriptions.length) return const SizedBox.shrink();
                                    final subscription = filteredSubscriptions[index];
                                    final user = users.firstWhereOrNull((u) => u.userId == subscription.userId);
                                    final transaction = transactions.firstWhereOrNull((t) => t.id == subscription.lastTransactionId);
                                    return _buildSubscriptionCard(subscription, user, transaction, index);
                                  },
                                  childCount: filteredSubscriptions.length,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: AppColors.overlay,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}