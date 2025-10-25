import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/validators.dart';
import '../providers/auth_provider.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoController = TextEditingController();
  int _numberOfPlayers = 11;
  bool _isRecruiting = false;
  bool _isLoading = false;
  // Local submitting flag to prevent duplicate submissions and disable button while submitting.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    // Validate synchronously
    if (!_formKey.currentState!.validate()) return;

    // Check if user is authenticated
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login to create a team'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        context.go('/login');
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    try {
      final apiService = ApiService();
      // Debug: Check authentication status
      final authProvider = context.read<AuthProvider>();
      print('DEBUG: User authenticated: ${authProvider.isAuthenticated}');
      print('DEBUG: Current user: ${authProvider.currentUser?.name ?? 'NULL'}');
      print('DEBUG: User ID: ${authProvider.currentUser?.id ?? 'NULL'}');

      await apiService.createTeam(
        _nameController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        numberOfPlayers: _numberOfPlayers,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        logo: _logoController.text.trim().isEmpty ? null : _logoController.text.trim(),
        isRecruiting: _isRecruiting,
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
        if (errorMessage.contains('authorized') || errorMessage.contains('login') || errorMessage.contains('token')) {
          errorMessage = 'Please login again to create a team';
          // Clear auth and redirect to login
          await authProvider.logout();
          context.go('/login');
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $errorMessage'),
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
                  hintText: LocalizationService().translate('enter_team_name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => validateTeamName(value),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('location'),
                  hintText: LocalizationService().translate('enter_location'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                // Location is optional
              ),
              const SizedBox(height: 24),
              Text(
                LocalizationService().translate('number_of_players'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _numberOfPlayers,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('number_of_players'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                items: [5, 7, 9, 11, 13, 15, 18, 22].map((players) {
                  return DropdownMenuItem(
                    value: players,
                    child: Text('$players ${LocalizationService().translate('players')}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _numberOfPlayers = value ?? 11);
                },
                validator: (value) {
                  if (value == null) {
                    return LocalizationService().translate('number_of_players_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('team_description'),
                  hintText: LocalizationService().translate('enter_team_description'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                // Description is optional
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _logoController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('team_logo'),
                  hintText: LocalizationService().translate('enter_logo_url'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.image,
                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                // Logo is optional
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: Text(LocalizationService().translate('recruiting')),
                subtitle: Text(LocalizationService().translate('allow_join_requests')),
                value: _isRecruiting,
                onChanged: (value) => setState(() => _isRecruiting = value),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isSubmitting) ? null : _createTeam,
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
    );
  }
}