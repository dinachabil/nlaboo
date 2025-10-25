import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/team.dart';
import '../utils/validators.dart';

class CreateMatchScreen extends StatefulWidget {
  final String? preselectedTeam1Id;

  const CreateMatchScreen({super.key, this.preselectedTeam1Id});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final ApiService _apiService = ApiService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String? _selectedTeam1Id;
  String? _selectedTeam2Id;
  String _selectedMatchType = 'male';
  int _totalPlayers = 22;
  List<Team> _allTeams = [];
  bool _isLoading = false;
  bool _isLoadingTeams = true;
  // Local form submitting flag to prevent duplicate submissions.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTeam1Id = widget.preselectedTeam1Id;
    _loadAllTeams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTeams() async {
    try {
      // Auth token is now handled automatically by Supabase client

      final teams = await _apiService.getAllTeams();
      setState(() {
        _allTeams = teams;
        _isLoadingTeams = false;
      });
    } catch (error) {
      setState(() => _isLoadingTeams = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('failed_to_load_teams')}: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createMatch() async {
    // Synchronous form validation first.
    if (!_formKey.currentState!.validate()) return;

    final matchDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Validate date/time using shared validator (returns localized error key if invalid).
    final dateError = validateMatchDateTime(matchDateTime);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    try {
      // Auth token is now handled automatically by Supabase client

      await _apiService.createMatch(
        team1Id: _selectedTeam1Id!,
        team2Id: _selectedTeam2Id!,
        matchDate: matchDateTime,
        location: _locationController.text.trim(),
        title: _titleController.text.trim(),
        maxPlayers: _totalPlayers,
        matchType: _selectedMatchType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('match_created_successfully'),
            ),
          ),
        );
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('error')}: $error',
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
        title: Text(LocalizationService().translate('create_match')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _isLoadingTeams
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacitySafe(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_circle,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocalizationService().translate('create_new_match'),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationService().translate('set_up_new_match'),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacitySafe(0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Match Title
                    Text(
                      LocalizationService().translate('match_title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: LocalizationService().translate(
                          'match_title_hint',
                        ),
                        prefixIcon: Icon(
                          Icons.title,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacitySafe(0.6),
                        ),
                      ),
                      validator: (value) => validateMatchTitle(value),
                    ),

                    const SizedBox(height: 24),

                    // Team 1 Selection
                    Text(
                      'Team 1',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTeam1Id,
                      decoration: InputDecoration(
                        hintText: 'Select Team 1',
                        prefixIcon: Icon(
                          Icons.group,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacitySafe(0.6),
                        ),
                      ),
                      items: _allTeams.map((team) {
                        return DropdownMenuItem(
                          value: team.id,
                          child: Text(team.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTeam1Id = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select Team 1';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Team 2 Selection
                    Text(
                      'Team 2',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTeam2Id,
                      decoration: InputDecoration(
                        hintText: 'Select Team 2',
                        prefixIcon: Icon(
                          Icons.group,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacitySafe(0.6),
                        ),
                      ),
                      items: _allTeams.map((team) {
                        return DropdownMenuItem(
                          value: team.id,
                          child: Text(team.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTeam2Id = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select Team 2';
                        }
                        if (_selectedTeam1Id == value) {
                          return 'Team 1 and Team 2 must be different';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    // Location
                    Text(
                      LocalizationService().translate('location'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
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
                      validator: (value) => validateLocation(value),
                    ),

                    const SizedBox(height: 24),

                    // Total Players
                    Text(
                      LocalizationService().translate('max_players'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _totalPlayers,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.people,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacitySafe(0.6),
                        ),
                      ),
                      items: [11, 15, 18, 22, 25, 30].map((players) {
                        return DropdownMenuItem(
                          value: players,
                          child: Text(
                            '$players ${LocalizationService().translate('players')}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _totalPlayers = value ?? 22);
                      },
                      validator: (value) => validateMaxPlayers(value),
                    ),

                    const SizedBox(height: 24),

                    // Match Type Selection
                    Text(
                      LocalizationService().translate('match_type'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMatchType,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.group_work,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacitySafe(0.6),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'mixed',
                          child: Text(LocalizationService().translate('mixed')),
                        ),
                        DropdownMenuItem(
                          value: 'male',
                          child: Text(LocalizationService().translate('male')),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text(
                            LocalizationService().translate('female'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedMatchType = value ?? 'mixed');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return LocalizationService().translate(
                            'match_type_required',
                          );
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Date Selection
                    Text(
                      LocalizationService().translate('match_date'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Time Selection
                    Text(
                      LocalizationService().translate('match_time'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.access_time,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacitySafe(0.6),
                          ),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isSubmitting)
                            ? null
                            : _createMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
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
                                LocalizationService().translate('create_match'),
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
    );
  }
}
