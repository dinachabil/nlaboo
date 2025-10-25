import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/validators.dart';
import '../widgets/footer.dart';

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
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _apiService = ApiService();

  String? _selectedGender;
  Uint8List? _avatarImage;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isInitialized = false;

  // Store original values to detect changes
  late String _originalName;
  late String _originalPosition;
  late String _originalBio;
  late String _originalPhone;
  late String _originalAge;
  late String _originalLocation;
  late String _originalGender;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Get fresh user data
      final user = await _apiService.getCurrentUser();

      if (mounted) {
        // Initialize form with current user data
        _nameController.text = user.name;
        _positionController.text = user.position ?? '';
        _bioController.text = user.bio ?? '';
        _phoneController.text = user.phone ?? '';
        _ageController.text = user.age?.toString() ?? '';
        _locationController.text = user.location ?? '';
        _selectedGender = user.gender;

        // Store original values for change detection
        _originalName = user.name;
        _originalPosition = user.position ?? '';
        _originalBio = user.bio ?? '';
        _originalPhone = user.phone ?? '';
        _originalAge = user.age?.toString() ?? '';
        _originalLocation = user.location ?? '';
        _originalGender = user.gender ?? '';

        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data. Please try again.'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadUserData),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _avatarImage = bytes);
    }
  }

  void _deleteImage() {
    setState(() => _avatarImage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService().translate('picture_deleted')),
      ),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_avatarImage != null) {
        imageUrl = await _apiService.uploadAvatarBytes(
          _avatarImage!,
          'avatar.jpg',
        );
      }

      // Detect changes by comparing with original values
      final name = _nameController.text.trim() != _originalName
          ? _nameController.text.trim()
          : null;
      final position = _positionController.text.trim() != _originalPosition
          ? _positionController.text.trim()
          : null;
      final bio = _bioController.text.trim() != _originalBio
          ? _bioController.text.trim()
          : null;
      final phone = _phoneController.text.trim() != _originalPhone
          ? _phoneController.text.trim()
          : null;
      final age = _ageController.text.trim() != _originalAge
          ? int.tryParse(_ageController.text.trim())
          : null;
      final location = _locationController.text.trim() != _originalLocation
          ? _locationController.text.trim()
          : null;
      final gender = _selectedGender != _originalGender
          ? _selectedGender
          : null;

      // Update profile with only changed fields
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.updateProfile(
        name: name,
        position: position,
        bio: bio,
        phone: phone,
        age: age,
        location: location,
        gender: gender,
        imageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('profile_updated')),
          ),
        );
        context.go('/profile');
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (_isLoading || !_isInitialized || user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(LocalizationService().translate('edit_profile')),
          leading: TextButton(
            onPressed: () => context.go('/profile'),
            child: Text(
              LocalizationService().translate('back_to_profile'),
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(LocalizationService().translate('loading')),
            ],
          ),
        ),
        persistentFooterButtons: const [Footer()],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('edit_profile')),
        leading: TextButton(
          onPressed: () => context.go('/profile'),
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
                horizontal: MediaQuery.of(context).size.width > 900
                    ? 48.0
                    : MediaQuery.of(context).size.width > 600
                    ? 32.0
                    : 24.0,
                vertical: 24.0,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width > 900
                    ? constraints.maxWidth * 0.5
                    : MediaQuery.of(context).size.width > 600
                    ? constraints.maxWidth * 0.7
                    : double.infinity,
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
                                ? MemoryImage(_avatarImage!)
                                : (user.imageUrl != null
                                          ? NetworkImage(user.imageUrl!)
                                          : null)
                                      as ImageProvider?,
                            child: _avatarImage == null && user.imageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacitySafe(0.6),
                                  )
                                : null,
                          ),
                          if (_avatarImage != null || user.imageUrl != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  onPressed: _deleteImage,
                                  tooltip: LocalizationService().translate(
                                    'delete_picture',
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: _pickImage,
                                tooltip: LocalizationService().translate(
                                  'change_picture',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Profile Form Fields
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate(
                            'full_name',
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        validator: (value) => validateName(value),
                      ),

                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate('bio'),
                          hintText: LocalizationService().translate('bio_hint'),
                          prefixIcon: Icon(
                            Icons.description,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 200,
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate('phone'),
                          hintText: LocalizationService().translate(
                            'phone_hint',
                          ),
                          prefixIcon: Icon(
                            Icons.phone,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 30,
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate('age'),
                          hintText: LocalizationService().translate('age_hint'),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => validateAgeOptional(value),
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate(
                            'location',
                          ),
                          hintText: LocalizationService().translate(
                            'location_hint',
                          ),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate('gender'),
                          prefixIcon: Icon(
                            Icons.person,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text(
                              LocalizationService().translate('male'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text(
                              LocalizationService().translate('female'),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                      ),

                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: (_isSubmitting)
                              ? null
                              : _showSaveConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            elevation: 4,
                            shadowColor: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha((0.3 * 255).round()),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
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
