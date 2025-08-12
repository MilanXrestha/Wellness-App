import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/preferences/data/models/user_preference_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/common/widgets/custom_bottom_sheet.dart';
import 'dart:convert';
import 'dart:developer';

class SendNotificationScreen extends StatefulWidget {
  final List<String> selectedUserIds;

  const SendNotificationScreen({super.key, required this.selectedUserIds});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  TipModel? _selectedTip;
  bool _isLoading = false;
  List<TipModel> _availableTips = [];
  Set<String> _userPreferenceIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserPreferencesAndTips();
  }

  Future<void> _loadUserPreferencesAndTips() async {
    setState(() => _isLoading = true);
    try {
      final prefSnapshots = await Future.wait(
        widget.selectedUserIds.map((userId) => _firestore.collection('userPreferences').doc(userId).get()),
      );

      _userPreferenceIds = prefSnapshots
          .where((doc) => doc.exists)
          .expand((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return <UserPreferenceModel>[];
        return [UserPreferenceModel.fromFirestore(data, doc.id)];
      })
          .expand((pref) => pref.preferences)
          .map((pref) => pref.preferenceId)
          .toSet();

      if (_userPreferenceIds.isEmpty) {
        if (mounted) {
          CustomBottomSheet.show(
            context: context,
            message: 'No preferences found for selected users. Sending to all selected users.',
            isSuccess: false,
          );
        }
      }

      const batchSize = 10;
      final preferenceBatches = [];
      final prefList = _userPreferenceIds.toList();
      for (var i = 0; i < prefList.length; i += batchSize) {
        preferenceBatches.add(prefList.sublist(i, i + batchSize > prefList.length ? prefList.length : i + batchSize));
      }

      final tipSnapshots = await Future.wait(
        preferenceBatches.isNotEmpty
            ? preferenceBatches.map((batch) => _firestore
            .collection('tips')
            .where('preferenceIds', arrayContainsAny: batch)
            .limit(10)
            .get())
            : [_firestore.collection('tips').limit(10).get()],
      );

      _availableTips = tipSnapshots
          .expand((snapshot) => snapshot.docs)
          .map((doc) {
        try {
          return TipModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e, stackTrace) {
          log('Error parsing TipModel for doc ${doc.id}: $e', stackTrace: stackTrace);
          return null;
        }
      })
          .whereType<TipModel>()
          .toList();

      if (_availableTips.isEmpty) {
        log('No valid tips found for preferences: $_userPreferenceIds');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      log('Error loading preferences and tips: $e', stackTrace: stackTrace);
      if (mounted) {
        CustomBottomSheet.show(context: context, message: '${AppStrings.error} $e', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendNotifications() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      CustomBottomSheet.show(
        context: context,
        message: 'Please enter a title and body for the notification.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('No ID token available');
      }

      final response = await http.post(
        Uri.parse('https://wellness-functions.vercel.app/api/sendNotifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'tipId': _selectedTip?.tipsId ?? '',
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'type': _selectedTip?.tipsType ?? 'custom',
          'preferenceIds': _userPreferenceIds.isNotEmpty ? _userPreferenceIds.toList() : ['all'],
          'senderUserId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          'selectedUserIds': widget.selectedUserIds,
        }),
      );

      log('HTTP Response: ${response.statusCode} - ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        if (mounted) {
          CustomBottomSheet.show(
            context: context,
            message: 'Notifications sent to ${responseData['sent']} users!',
            isSuccess: true,
            onOkPressed: () => Navigator.pop(context),
          );
        }
      } else {
        if (mounted) {
          CustomBottomSheet.show(
            context: context,
            message: 'Failed to send notifications: ${responseData['error'] ?? 'Unknown error'}',
            isSuccess: false,
          );
        }
      }
    } catch (e, stackTrace) {
      log('HTTP Error: $e', stackTrace: stackTrace);
      if (mounted) {
        CustomBottomSheet.show(
          context: context,
          message: '${AppStrings.error} Failed to connect to server: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Send Notifications',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Users: ${widget.selectedUserIds.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    ),
                    maxLength: 80,
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _bodyController,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: 'Notification Body',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Select Tip/Quote (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<TipModel>(
                    value: _selectedTip,
                    hint: Text('Select a tip or quote'),
                    items: _availableTips.map((tip) {
                      return DropdownMenuItem(
                        value: tip,
                        child: Text(
                          '${tip.tipsTitle} (${tip.tipsType.capitalize()})',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.sp),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTip = value;
                        if (value != null) {
                          _titleController.text = 'New ${value.tipsType.capitalize()}';
                          _bodyController.text = value.tipsTitle;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    ),
                    isExpanded: true,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      minimumSize: Size(double.infinity, 48.h),
                    ),
                    child: Text(
                      'Send Notifications',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
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