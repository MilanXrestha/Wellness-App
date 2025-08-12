import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/routes/route_name.dart';

/// A screen to add health tips with a selected category.
class AddHealthTipsScreen extends StatefulWidget {
  const AddHealthTipsScreen({super.key});

  @override
  State<AddHealthTipsScreen> createState() => _AddHealthTipsScreenState();
}

class _AddHealthTipsScreenState extends State<AddHealthTipsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tipsController = TextEditingController();
  final String _selectedCategory = 'Health';

  @override
  void dispose() {
    _tipsController.dispose();
    super.dispose();
  }

  bool _isFormValid() => _tipsController.text.trim().isNotEmpty;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: implement submission logic
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          'Add Health Tips',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: 16.sp,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              RoutesName.adminDashboardScreen,
            );
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            // Category
            Text(
              'Select Category:',
              style: _labelStyle(),
            ),
            SizedBox(height: 8.h),
            _buildDropdown(theme),
            SizedBox(height: 24.h),

            // Tips input
            Text(
              'Health Tips:',
              style: _labelStyle(),
            ),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _tipsController,
              hintText: 'Write a health tips',
              maxLines: 6,
            ),
            SizedBox(height: 60.h),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  disabledBackgroundColor: const Color(0xFF444444).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: _isFormValid() ? _submit : null,
                child: Text(
                  'Save',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: 14.sp,
    fontFamily: 'Poppins',
  );

  Widget _buildDropdown(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        items: ['Health'].map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(
              category,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (_) {},
        dropdownColor: const Color(0xFF242424),
        iconEnabledColor: Colors.white70,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required int maxLines,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white54,
          fontSize: 14.sp,
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: const Color(0xFF222222),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
      validator: (value) =>
      value == null || value.trim().isEmpty ? 'Please write a health tip' : null,
    );
  }
}
