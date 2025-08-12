import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/resources/colors.dart';

class CustomCropperScreen extends StatefulWidget {
  final File imageFile;

  const CustomCropperScreen({super.key, required this.imageFile});

  @override
  State<CustomCropperScreen> createState() => _CustomCropperScreenState();
}

class _CustomCropperScreenState extends State<CustomCropperScreen> {
  final controller = CropController(
    aspectRatio: 1.0,
    defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      _imageBytes = await widget.imageFile.readAsBytes();
      setState(() {});
      print('Image bytes loaded: ${_imageBytes?.length} bytes');
    } catch (e) {
      print('Error loading image bytes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Uint8List?> _captureCircularCroppedImage() async {
    try {
      final croppedImage = await controller.croppedBitmap();
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      final croppedBytes = byteData!.buffer.asUint8List();

      final codec = await ui.instantiateImageCodec(croppedBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final size = image.width.toDouble();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
      final paint = Paint()..isAntiAlias = true;

      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: size / 2)),
      );

      canvas.drawImage(image, Offset.zero, paint);

      final picture = recorder.endRecording();
      final circularImage = await picture.toImage(size.toInt(), size.toInt());
      final circularByteData = await circularImage.toByteData(format: ui.ImageByteFormat.png);
      final circularBytes = circularByteData!.buffer.asUint8List();

      print('Circular cropped image captured: ${circularBytes.length} bytes');
      return circularBytes;
    } catch (e) {
      print('Error capturing circular cropped image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cropping image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      print('Crop cancelled');
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Crop Profile Picture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: _imageBytes == null
                        ? null
                        : () async {
                      try {
                        final bytes = await _captureCircularCroppedImage();
                        if (bytes != null) {
                          final croppedFile = File('${widget.imageFile.path}.cropped.png');
                          await croppedFile.writeAsBytes(bytes);
                          print('Cropped image saved: ${croppedFile.path}');
                          Navigator.pop(context, croppedFile);
                        }
                      } catch (e) {
                        print('Error cropping image: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error cropping image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _imageBytes == null
                  ? const Center(child: CircularProgressIndicator())
                  : CropImage(
                controller: controller,
                image: Image.memory(_imageBytes!),  // pass raw Uint8List
                gridColor: isDarkMode ? Colors.white70 : AppColors.primary,
                gridCornerSize: 24.0,
                minimumImageSize: 50.0,
                paddingSize: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
