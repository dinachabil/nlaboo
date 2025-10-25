import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/team_service.dart';
import '../services/user_service.dart';
import '../services/localization_service.dart';
import '../utils/validators.dart';
import '../providers/auth_provider.dart';
import '../models/city.dart';
import '../repositories/team_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  late final TeamService _teamService;
  late final UserService _userService;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _uploadedImageUrl;
  City? _selectedCity; // Selected city object
  int _numberOfPlayers = 11;
  int _minAge = 15;
  int _maxAge = 40;
  bool _isRecruiting = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isLoadingCities = true; // Loading state for cities
  // Local submitting flag to prevent duplicate submissions and disable button while submitting.
  bool _isSubmitting = false;

  // Available cities fetched from API
  List<City> _availableCities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auth token is now handled automatically by Supabase client
      final apiService = ApiService();

      // Initialize repositories and services
      final teamRepository = TeamRepository(apiService);
      final userRepository = UserRepository(apiService);
      _teamService = TeamService(teamRepository);
      _userService = UserService(userRepository);

      _loadCities();
    });
  }

  Future<void> _loadCities() async {
    if (mounted) {
      setState(() {
        _isLoadingCities = true;
      });
    }

    try {
      final cities = await _teamService.getCities();
      if (mounted) {
        setState(() {
          _availableCities = cities;
          // No default city selection - user must choose
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _userService.uploadAvatar(_selectedImage!);
      setState(() {
        _uploadedImageUrl = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _createTeam() async {
    // Validate synchronously
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    try {
      await _teamService.createTeam(
        name: _nameController.text.trim(),
        location: _selectedCity?.name,
        numberOfPlayers: _numberOfPlayers,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        logo: _uploadedImageUrl,
        isRecruiting: _isRecruiting,
        minAge: _minAge,
        maxAge: _maxAge,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('team_created')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // Handle duplicate team name error
        if (errorMessage.contains('already have a team with this name')) {
          errorMessage = 'You already have a team with this name';
        }

        // Handle auth errors
        if (errorMessage.contains('authorized') ||
            errorMessage.contains('login') ||
            errorMessage.contains('token')) {
          errorMessage = 'Please login again to create a team';
          // Clear auth and redirect to login with confirmation
          final authProvider = context.read<AuthProvider>();
          await authProvider.logoutWithConfirmation(context);
          if (mounted) {
            context.go('/login');
          }
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('error')}: $errorMessage',
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('create_team')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  LocalizationService().translate('team_name'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: LocalizationService().translate('team_name'),
                    hintText: LocalizationService().translate(
                      'enter_team_name',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => validateTeamName(value),
                ),
                const SizedBox(height: 24),
                _isLoadingCities
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<City>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate(
                            'location',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.location_city,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        items: _availableCities.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCity = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return LocalizationService().translate(
                              'location_required',
                            );
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 24),
                Text(
                  LocalizationService().translate('max_players'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _numberOfPlayers,
                  decoration: InputDecoration(
                    labelText: LocalizationService().translate(
                      'number_of_players',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.people,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  items: [5, 7, 9, 11, 13, 15, 18, 22].map((players) {
                    return DropdownMenuItem(
                      value: players,
                      child: Text(
                        '$players ${LocalizationService().translate('players')}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _numberOfPlayers = value ?? 11);
                  },
                  validator: (value) {
                    if (value == null) {
                      return LocalizationService().translate(
                        'number_of_players_required',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  LocalizationService().translate('age_restrictions'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _minAge,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate('min_age'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacitySafe(0.6),
                          ),
                        ),
                        items: List.generate(51, (index) => index + 10)
                            .map((age) => DropdownMenuItem(
                                  value: age,
                                  child: Text('$age'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _minAge = value ?? 15);
                        },
                        validator: (value) {
                          if (value == null) {
                            return LocalizationService().translate('min_age_required');
                          }
                          if (value > _maxAge) {
                            return LocalizationService().translate('min_age_cannot_be_greater_than_max');
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _maxAge,
                        decoration: InputDecoration(
                          labelText: LocalizationService().translate('max_age'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacitySafe(0.6),
                          ),
                        ),
                        items: List.generate(51, (index) => index + 10)
                            .map((age) => DropdownMenuItem(
                                  value: age,
                                  child: Text('$age'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _maxAge = value ?? 40);
                        },
                        validator: (value) {
                          if (value == null) {
                            return LocalizationService().translate('max_age_required');
                          }
                          if (value < _minAge) {
                            return LocalizationService().translate('max_age_cannot_be_less_than_min');
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: LocalizationService().translate(
                      'team_description',
                    ),
                    hintText: LocalizationService().translate(
                      'enter_team_description',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.description,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  // Description is optional
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService().translate('team_logo'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withAlpha((0.3 * 255).round()),
                              width: 2,
                            ),
                          ),
                          child: _isUploadingImage
                              ? const Center(child: CircularProgressIndicator())
                              : _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload Logo',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    if (_uploadedImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Logo uploaded successfully',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: Text(LocalizationService().translate('recruiting')),
                  subtitle: Text(
                    LocalizationService().translate('allow_join_requests'),
                  ),
                  value: _isRecruiting,
                  onChanged: (value) => setState(() => _isRecruiting = value),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isSubmitting)
                        ? null
                        : _createTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      disabledBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.12 * 255).round()),
                      disabledForegroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.38 * 255).round()),
                      elevation: 4,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha((0.3 * 255).round()),
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
                            LocalizationService().translate('create_team'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
