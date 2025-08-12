import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/routes/route_name.dart';

/// A screen to let admin add quotes with category, author name, and the quote itself.
class AddQuoteScreen extends StatefulWidget {
  const AddQuoteScreen({super.key});

  @override
  State<AddQuoteScreen> createState() => _AddQuoteScreenState();
}

class _AddQuoteScreenState extends State<AddQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authorController = TextEditingController();
  final _quoteController = TextEditingController();

  String _selectedCategory = 'Quotes';

  @override
  void dispose() {
    _authorController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _authorController.text.trim().isNotEmpty &&
        _quoteController.text.trim().isNotEmpty;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save logic
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          'Add Quote',
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
            // Select Category
            Text('Select Category:', style: _labelStyle()),
            SizedBox(height: 8.h),
            _buildDropdown(theme),
            SizedBox(height: 24.h),

            // Author Name
            Text('Author Name:', style: _labelStyle()),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _authorController,
              hintText: 'Author Name',
              maxLines: 1,
            ),
            SizedBox(height: 24.h),

            // Quote Text
            Text('Quote:', style: _labelStyle()),
            SizedBox(height: 8.h),
            _buildTextField(
              controller: _quoteController,
              hintText: 'Write a quote',
              maxLines: 6,
            ),
            SizedBox(height: 60.h),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF444444),
                  disabledBackgroundColor: const Color(
                    0xFF444444,
                  ).withOpacity(0.4),
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

  // Styles
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
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        items: ['Quotes', 'Health'].map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
          });
        },
        dropdownColor: const Color(0xFF202020),
        iconEnabledColor: Colors.white70,
        decoration: const InputDecoration(border: InputBorder.none),
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
      validator: (value) => value == null || value.trim().isEmpty
          ? 'This field is required'
          : null,
    );
  }
}
