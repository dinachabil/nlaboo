import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/image_management_service.dart';
import '../services/localization_service.dart';
import 'loading_overlay.dart';

/// Extension to provide context-based localization access
extension LocalizationExtension on BuildContext {
  LocalizationService get localization => LocalizationService();
}

/// A comprehensive image picker widget with camera/gallery options
class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImageSelected;
  final bool allowCamera;
  final bool allowGallery;
  final String? title;
  final String? subtitle;
  final double? maxWidth;
  final double? maxHeight;
  final int? imageQuality;
  final bool isAvatar; // true for avatars, false for team logos

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.allowCamera = true,
    this.allowGallery = true,
    this.title,
    this.subtitle,
    this.maxWidth,
    this.maxHeight,
    this.imageQuality,
    this.isAvatar = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  final ImageManagementService _imageService = ImageManagementService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.allowCamera)
                _buildOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed: _pickFromCamera,
                ),
              if (widget.allowGallery)
                _buildOptionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed: _pickFromGallery,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isAvatar
                ? 'Max 5MB, recommended 512x512px'
                : 'Max 10MB, recommended 1024x1024px',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      // Request permissions
      final permission = source == ImageSource.camera
          ? Permission.camera
          : Permission.photos;

      final status = await permission.request();
      if (!status.isGranted) {
        _showPermissionDeniedDialog();
        return;
      }

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
        imageQuality: widget.imageQuality ?? (widget.isAvatar ? 90 : 85),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Validate image before passing it back
        await _imageService.validateImage(file, isAvatar: widget.isAvatar);

        widget.onImageSelected(file);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Please grant permission to access camera/gallery in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to pick image: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// A dialog wrapper for the image picker widget
class ImagePickerDialog extends StatelessWidget {
  final Function(File) onImageSelected;
  final bool allowCamera;
  final bool allowGallery;
  final String? title;
  final String? subtitle;
  final bool isAvatar;

  const ImagePickerDialog({
    super.key,
    required this.onImageSelected,
    this.allowCamera = true,
    this.allowGallery = true,
    this.title,
    this.subtitle,
    this.isAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ImagePickerWidget(
          onImageSelected: (file) {
            Navigator.of(context).pop();
            onImageSelected(file);
          },
          allowCamera: allowCamera,
          allowGallery: allowGallery,
          title: title,
          subtitle: subtitle,
          isAvatar: isAvatar,
        ),
      ),
    );
  }

  static Future<File?> show(
    BuildContext context, {
    bool allowCamera = true,
    bool allowGallery = true,
    String? title,
    String? subtitle,
    bool isAvatar = true,
  }) async {
    File? selectedFile;
    await showDialog(
      context: context,
      builder: (context) => ImagePickerDialog(
        onImageSelected: (file) => selectedFile = file,
        allowCamera: allowCamera,
        allowGallery: allowGallery,
        title: title,
        subtitle: subtitle,
        isAvatar: isAvatar,
      ),
    );
    return selectedFile;
  }
}