import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wellness_app/admin/admin_dashboard_screen.dart';

import '../core/route_config/route_config.dart';

/// A form that lets the admin create a new category (Quotes / Health).
class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedType = 'Quotes';
  File? _pickedImage;

  Future<void> _pickImage() async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (file != null) setState(() => _pickedImage = File(file.path));
    } catch (_) {
      /* handle errors */
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontSize: 12.sp,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 0,
        title: Text('Add Category', style: _titleStyle(theme)),
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
            //  NAME
            Text(
              'Category Name:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 15.h),
            _buildNameField(theme),
            SizedBox(height: 24.h),

            // TYPE
            Text(
              'Category Type:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 15.h),
            Row(
              children: [
                _typeButton('Quotes'),
                SizedBox(width: 12.w),
                _typeButton('Health'),
              ],
            ),
            SizedBox(height: 24.h),

            // IMAGE
            Text(
              'Choose image for category:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 15.h),
            GestureDetector(onTap: _pickImage, child: _imageBox(theme)),
            SizedBox(height: 60.h),

            // SAVE
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
                child: Text('Save', style: _buttonStyle(theme)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widgets & helpers
  TextStyle _titleStyle(ThemeData theme) => theme.textTheme.bodyMedium!
      .copyWith(color: Colors.white, fontSize: 16.sp, fontFamily: 'Poppins');

  TextStyle _buttonStyle(ThemeData theme) => theme.textTheme.bodyMedium!
      .copyWith(color: Colors.white, fontSize: 14.sp, fontFamily: 'Poppins');

  Widget _buildNameField(ThemeData theme) => TextFormField(
    controller: _nameController,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: 'Category Name',
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
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'Please enter a name' : null,
  );

  Widget _imageBox(ThemeData theme) {
    return DottedBorder(
      color: Colors.white38,
      strokeWidth: 1,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: Radius.circular(6.r),
      child: Container(
        height: 100.h,
        width: double.infinity,
        color: const Color(0xFF111111),
        child: _pickedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, color: Colors.white, size: 32.sp),
                  SizedBox(height: 6.h),
                  Text(
                    'Tap to choose image',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Image.file(
                  _pickedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }

  // CUSTOM RADIO
  Widget _typeButton(String label) {
    final bool selected = _selectedType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = label),
        child: Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF222222) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white38, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _radioCircle(selected),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected) => Container(
    width: 16.r,
    height: 16.r,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: selected
        ? Center(
            child: Container(
              width: 8.r,
              height: 8.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          )
        : null,
  );

  bool _isFormValid() =>
      _nameController.text.trim().isNotEmpty && _pickedImage != null;

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: implement saving logic
    }
  }
}
