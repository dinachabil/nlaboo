import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _bioController = TextEditingController();
  final _apiService = ApiService();
  String? _selectedGender;
  File? _avatarImage;
  bool _isLoading = false;
  // Local submitting flag to prevent duplicate submits and disable button while submitting.
  bool _isSubmitting = false;
  bool _isGenderReadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _nameController.text = user.name;
        _positionController.text = user.position ?? '';
        _bioController.text = user.bio ?? '';
        _selectedGender = user.gender;
        // Gender is read-only after initial registration
        _isGenderReadOnly = user.gender != null;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  void _deleteImage() {
    setState(() {
      _avatarImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocalizationService().translate('picture_deleted'))),
    );
  }

  Future<void> _showSaveConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService().translate('confirm_save')),
        content: Text(LocalizationService().translate('confirm_save_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocalizationService().translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(LocalizationService().translate('save')),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    // Validate synchronously
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      String? imageUrl;

      if (_avatarImage != null) {
        imageUrl = await _apiService.uploadAvatar(_avatarImage!);
      }

      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        imageUrl: _avatarImage != null ? imageUrl : null,
        gender: _selectedGender,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate('profile_updated'))),
        );
        context.pop(); // back to ProfileScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900; // Tablet and desktop breakpoint
    final isMediumScreen = screenWidth > 600 && screenWidth <= 900; // Small tablet breakpoint

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('edit_profile')),
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            LocalizationService().translate('back_to_profile'),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 48.0 : (isMediumScreen ? 32.0 : 24.0),
                vertical: 24.0,
              ),
              child: Container(
                width: isLargeScreen ? constraints.maxWidth * 0.5 : (isMediumScreen ? constraints.maxWidth * 0.7 : double.infinity),
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
              // Avatar Section
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _avatarImage != null
                        ? FileImage(_avatarImage!)
                        : (user?.imageUrl != null
                            ? NetworkImage(user!.imageUrl!)
                            : null) as ImageProvider?,
                    child: _avatarImage == null && user?.imageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                          )
                        : null,
                  ),
                  if (_avatarImage != null || user?.imageUrl != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.error,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 14,
                          ),
                          onPressed: _deleteImage,
                          tooltip: LocalizationService().translate('delete_picture'),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: _pickImage,
                        tooltip: LocalizationService().translate('change_picture'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Profile Form
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('full_name'),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                // Use shared validator
                validator: (value) => validateName(value),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('position'),
                  hintText: LocalizationService().translate('position_hint'),
                  prefixIcon: Icon(
                    Icons.sports_soccer,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('bio'),
                  hintText: LocalizationService().translate('bio_hint'),
                  prefixIcon: Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                maxLines: 3,
                maxLength: 200,
              ),

              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('gender'),
                  prefixIcon: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                  helperText: _isGenderReadOnly ? LocalizationService().translate('gender_readonly_hint') : null,
                ),
                items: _isGenderReadOnly ? [
                  // Show current value as disabled when read-only
                  DropdownMenuItem(
                    value: _selectedGender,
                    child: Text(_selectedGender == 'male' ? LocalizationService().translate('male') : LocalizationService().translate('female')),
                  ),
                ] : [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(LocalizationService().translate('male')),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(LocalizationService().translate('female')),
                  ),
                ],
                onChanged: _isGenderReadOnly ? null : (value) {
                  setState(() => _selectedGender = value);
                },
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isSubmitting) ? null : _showSaveConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                    disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                    elevation: 4,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: (_isLoading || _isSubmitting)
                      ? SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          LocalizationService().translate('save'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}