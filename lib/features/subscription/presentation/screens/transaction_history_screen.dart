import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/subscription/data/models/transaction_model.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';

import '../../../../core/services/data_repository.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final AuthService _authService = AuthService();
  final DataRepository _dataRepository = DataRepository.instance;

  Widget _buildTransactionCard(TransactionModel transaction, ThemeData theme, bool isDarkMode, SubscriptionModel? subscription) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCancellation = transaction.status == 'cancelled';
    final subscriptionStatus = subscription != null ? ' (${subscription.status.toUpperCase()})' : '';

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () {}, // Add onTap if needed (e.g., view details)
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCancellation ? Icons.cancel : Icons.receipt,
                      size: 20.sp,
                      color: isCancellation ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCancellation
                              ? 'Subscription Cancelled'
                              : '${transaction.planId.toUpperCase()} Plan$subscriptionStatus',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isCancellation
                              ? 'Cancelled on ${dateFormat.format(transaction.createdAt ?? DateTime.now())}'
                              : 'NPR ${transaction.amount.toStringAsFixed(2)} • ${dateFormat.format(transaction.createdAt ?? DateTime.now())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    transaction.status.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: transaction.status == 'completed' ? AppColors.primary : AppColors.error,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
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
                                  'Transaction History',
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
                            Opacity(
                              opacity: 0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  size: 24.sp,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                onPressed: null, // Dummy for symmetry
                              ),
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
                    child: FutureBuilder<List<TransactionModel>>(
                      future: _dataRepository.getTransactions(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 4.w,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Container(
                              padding: EdgeInsets.all(16.w),
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
                              child: Text(
                                'No transactions found.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 16.sp,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          );
                        }
                        return FutureBuilder<SubscriptionModel?>(
                          future: _dataRepository.getSubscription(userId),
                          builder: (context, subscriptionSnapshot) {
                            if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 4.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              );
                            }
                            final subscription = subscriptionSnapshot.data;
                            return Column(
                              children: snapshot.data!.asMap().entries.map((entry) {
                                final index = entry.key;
                                final transaction = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8.h),
                                  child: _buildTransactionCard(transaction, theme, isDarkMode, subscription),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}