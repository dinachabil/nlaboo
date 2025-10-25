import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/match.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Match> _matches = [];
  List<Match> _filteredMatches = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedLocation = 'Nador'; // Default to Nador
  int? _selectedPlayersNeeded;
  String _selectedAvailability = 'all'; // all, open, closed

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await _apiService.getMatches();
      if (mounted) {
        setState(() {
          _matches = matches;
          _filteredMatches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('failed_to_load')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterMatches() {
    setState(() {
      _filteredMatches = _matches.where((match) {
        // Guard nullable match fields when filtering
        final matchesSearch = _searchQuery.isEmpty ||
            (match.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (match.location.toLowerCase().contains(_searchQuery.toLowerCase()));

        final matchesLocation = _selectedLocation.isEmpty ||
            (match.location.toLowerCase().contains(_selectedLocation.toLowerCase()));

        final matchesPlayers = _selectedPlayersNeeded == null ||
            (match.defaultMaxPlayers == _selectedPlayersNeeded);

        final matchesAvailability = _selectedAvailability == 'all' ||
            (_selectedAvailability == 'open' && match.isOpen) ||
            (_selectedAvailability == 'closed' && match.isClosed);

        // Skill level not implemented yet, so always true
        final matchesSkill = true;

        return matchesSearch && matchesLocation && matchesPlayers && matchesAvailability && matchesSkill;
      }).toList();
    });
  }



  String _getLocalizedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return LocalizationService().translate('open');
      case 'closed':
        return LocalizationService().translate('closed');
      case 'pending':
        return LocalizationService().translate('pending');
      case 'confirmed':
        return LocalizationService().translate('confirmed');
      case 'finished':
        return LocalizationService().translate('finished');
      case 'cancelled':
        return LocalizationService().translate('cancelled');
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'closed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'finished':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('home_title')),
        actions: [
          // Profile Button
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: LocalizationService().translate('profile'),
            onPressed: () => context.go('/profile'),
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: LocalizationService().translate('settings'),
            onPressed: () => context.go('/settings'),
          ),
          // Teams Button
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: LocalizationService().translate('teams'),
            onPressed: () => context.go('/teams'),
          ),
          // Create Team Button
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: LocalizationService().translate('create_team'),
            onPressed: () => context.go('/create-team'),
          ),
          // Notifications Button
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: LocalizationService().translate('notifications'),
            onPressed: () => context.go('/notifications'),
          ),
          // Admin Button (if admin)
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: LocalizationService().translate('admin_dashboard'),
              onPressed: () => context.go('/admin'),
            ),
          // Logout Button with confirmation
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(LocalizationService().translate('logout')),
                    content: Text(LocalizationService().translate('logout_confirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        child: Text(LocalizationService().translate('cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: Text(
                          LocalizationService().translate('logout'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true) {
                  try {
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Logout failed: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      LocalizationService().translate('logout'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
            tooltip: LocalizationService().translate('settings'),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading matches...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacitySafe(0.2),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth > 600;
                      return Column(
                        children: [
                          // Search TextField
                          TextField(
                            decoration: InputDecoration(
                              hintText: LocalizationService().translate('search_matches'),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            style: const TextStyle(fontSize: 16),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                              _filterMatches();
                            },
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 16),
                          // Filters Row
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              // Location Filter
                              SizedBox(
                                width: isWideScreen ? 150 : double.infinity,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedLocation,
                                  decoration: InputDecoration(
                                    labelText: LocalizationService().translate('location'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: ['Nador', 'Tangier', 'Tetouan', 'Chefchaouen'].map((location) {
                                    return DropdownMenuItem(
                                      value: location,
                                      child: Text(location),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedLocation = value ?? 'Nador');
                                    _filterMatches();
                                  },
                                ),
                              ),
                              // Players Needed Filter
                              SizedBox(
                                width: isWideScreen ? 150 : double.infinity,
                                child: DropdownButtonFormField<int?>(
                                  initialValue: _selectedPlayersNeeded,
                                  decoration: InputDecoration(
                                    labelText: LocalizationService().translate('players_needed'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('All')),
                                    ...[11, 15, 18, 22].map((players) {
                                      return DropdownMenuItem(
                                        value: players,
                                        child: Text('$players ${LocalizationService().translate('players')}'),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedPlayersNeeded = value);
                                    _filterMatches();
                                  },
                                ),
                              ),
                              // Availability Filter
                              SizedBox(
                                width: isWideScreen ? 150 : double.infinity,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedAvailability,
                                  decoration: InputDecoration(
                                    labelText: LocalizationService().translate('availability'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: [
                                    DropdownMenuItem(value: 'all', child: Text(LocalizationService().translate('all'))),
                                    DropdownMenuItem(value: 'open', child: Text(LocalizationService().translate('open'))),
                                    DropdownMenuItem(value: 'closed', child: Text(LocalizationService().translate('closed'))),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedAvailability = value ?? 'all');
                                    _filterMatches();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Matches List
                Expanded(
                  child: _filteredMatches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 80,
                                color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                LocalizationService().translate('no_matches'),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LocalizationService().translate('check_back_later'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMatches,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWideScreen = constraints.maxWidth > 600;
                              return ListView.builder(
                                padding: EdgeInsets.all(isWideScreen ? 24 : 16),
                                itemCount: _filteredMatches.length,
                                itemBuilder: (context, index) {
                                  final match = _filteredMatches[index];
                                  final title = match.displayTitle;
                                  final location = match.location;
                                  final formattedDate = match.formattedDate;
                                  final maxPlayers = match.defaultMaxPlayers;
                                  final status = match.status;
    
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () => context.go('/match/${match.id}'),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.sports_soccer,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$location • $formattedDate',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(status).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    _getLocalizedStatus(status),
                                                    style: TextStyle(
                                                      color: _getStatusColor(status),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$maxPlayers ${LocalizationService().translate('players')}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: authProvider.isAuthenticated
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: () => context.go('/create-match'),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  LocalizationService().translate('create_match'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : null,
    );
  }
}