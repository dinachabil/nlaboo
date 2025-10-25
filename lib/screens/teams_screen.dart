import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../services/team_service.dart';
import '../services/user_service.dart';
import '../models/team.dart';
import '../models/city.dart';
import '../services/localization_service.dart';
import '../repositories/team_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../widgets/cached_image.dart';
import '../utils/responsive_utils.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late final TeamService _teamService;
  late final UserService _userService;
  Map<String, Map<String, dynamic>> _teamOwners = {}; // teamId -> owner info
  Map<String, int> _teamMemberCounts = {}; // teamId -> member count
  bool _isLoadingCities = true; // Loading state for cities
  String _selectedCity = 'Nador'; // Default city for filtering
  List<City> _availableCities = []; // Available cities fetched from API

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      // Auth token is now handled automatically by Supabase client

      // Initialize repositories and services
      final apiService = ApiService();
      final teamRepository = TeamRepository(apiService);
      final userRepository = UserRepository(apiService);
      _teamService = TeamService(teamRepository);
      _userService = UserService(userRepository);

      // Set UserService for batch operations
      _teamService.setUserService(_userService);

      _loadCities();
      // Load initial data
      final teamProvider = context.read<TeamProvider>();
      teamProvider.loadTeams();
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
          // Ensure selected city exists in the list, otherwise set to first available
          if (_availableCities.isNotEmpty &&
              !_availableCities.any((city) => city.name == _selectedCity)) {
            _selectedCity = _availableCities.first.name;
          }
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

  Future<void> _loadTeams() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final allTeams = await _teamService.getAllTeams();

      // Filter teams by selected city
      final teams = allTeams
          .where((team) => team.location == _selectedCity)
          .toList();

      // Sort teams to prioritize user's own teams first
      final userId = authProvider.user?.id;
      teams.sort((a, b) {
        final aIsOwned = a.ownerId == userId;
        final bIsOwned = b.ownerId == userId;
        if (aIsOwned && !bIsOwned) return -1;
        if (!aIsOwned && bIsOwned) return 1;
        return 0; // Keep original order for non-owned teams
      });

      // Use batch API calls for better performance
      final teamIds = teams.map((team) => team.id).toList();
      final batchData = await _teamService.getTeamDataBatch(teamIds);

      final ownersMap =
          batchData['owners'] as Map<String, Map<String, dynamic>>?;
      final memberCountsMap = batchData['memberCounts'] as Map<String, int>?;

      if (mounted) {
        setState(() {
          _teamOwners = ownersMap ?? {};
          _teamMemberCounts = memberCountsMap ?? {};
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }


  Future<void> _refreshTeams() async {
    await _loadTeams();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final teamProvider = context.watch<TeamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${LocalizationService().translate('teams')} - $_selectedCity',
        ),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          // City Filter Dropdown
          if (_isLoadingCities)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Semantics(
              label: 'Select city to filter teams',
              hint: 'Choose a city to display teams from that location',
              child: DropdownButton<String>(
                value: _selectedCity,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                underline: Container(),
                icon: Icon(
                  Icons.location_city,
                  color: Theme.of(context).colorScheme.onPrimary,
                  semanticLabel: 'City selection icon',
                ),
                items: _availableCities.map((city) {
                  return DropdownMenuItem(
                    value: city.name,
                    child: Text(
                      city.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCity = value);
                    _loadTeams();
                    // Screen reader announcement for state change
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Teams filtered by $value'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ),
          const SizedBox(width: 16),
          Semantics(
            label: 'Refresh teams list',
            hint: 'Reload the teams data from server',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshTeams,
              tooltip: 'Refresh Teams',
            ),
          ),
        ],
      ),
      body: teamProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : teamProvider.teams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${LocalizationService().translate('no_teams_found_in_city')} $_selectedCity',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocalizationService().translate(
                      'try_different_city_or_create_team',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTeams,
              child: GridView.builder(
                key: const PageStorageKey('teams_grid'),
                padding: context.responsivePadding,
                gridDelegate: ResponsiveUtils.getResponsiveGridDelegate(
                  context,
                  childAspectRatio: 0.75,
                ),
                itemCount: teamProvider.teams.length,
                itemBuilder: (context, index) {
                  final team = teamProvider.teams[index];
                  final isOwner = authProvider.user?.id == team.ownerId;
                  final ownerInfo =
                      _teamOwners[team.id] ?? const {'name': 'Unknown Owner'};
                  final memberCount = _teamMemberCounts[team.id] ?? 0;

                  return _TeamCard(
                    key: ValueKey(team.id),
                    team: team,
                    ownerInfo: ownerInfo,
                    memberCount: memberCount,
                    isOwner: isOwner,
                    onViewDetails: () => _showTeamDetails(context, team),
                    onJoinRequest: () => _showJoinRequestDialog(context, team),
                    onManage: () => _showTeamManagement(context, team),
                  );
                },
              ),
            ),
      floatingActionButton: Semantics(
        label: LocalizationService().translate('create_team'),
        hint: 'Create a new team to start organizing matches',
        child: FloatingActionButton(
          onPressed: () => context.push('/create-team'),
          tooltip: LocalizationService().translate('create_team'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showTeamDetails(BuildContext context, Team team) {
    context.push('/teams/${team.id}');
  }

  void _showTeamManagement(BuildContext context, Team team) {
    context.push('/teams/${team.id}/manage');
  }

  void _showJoinRequestDialog(BuildContext context, Team team) {
    final authProvider = context.read<AuthProvider>();
    final userAge = authProvider.user?.age;

    // Check if user can join based on age restrictions
    final canJoin = userAge == null ||
        (userAge >= team.minAge && userAge <= team.maxAge);

    if (!canJoin) {
      // Show age restriction dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(LocalizationService().translate('age_restriction')),
          content: Text(
            '${LocalizationService().translate('cannot_join_team_age')} ${team.minAge}–${team.maxAge}. ${LocalizationService().translate('your_age')}: ${userAge ?? 'Unknown'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService().translate('ok')),
            ),
          ],
        ),
      );
      return;
    }

    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${LocalizationService().translate('join_team')} ${team.name}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LocalizationService().translate('join_request_message_hint')),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: LocalizationService().translate('optional_message'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService().translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _teamService.createJoinRequest(
                  team.id,
                  message: messageController.text.trim().isEmpty
                      ? null
                      : messageController.text.trim(),
                );

                if (mounted && context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LocalizationService().translate('join_request_sent'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${LocalizationService().translate('error')}: $e',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(LocalizationService().translate('send_request')),
          ),
        ],
      ),
    );
  }
}

// Team Card Widget
class _TeamCard extends StatelessWidget {
  final Team team;
  final Map<String, dynamic> ownerInfo;
  final int memberCount;
  final bool isOwner;
  final VoidCallback onViewDetails;
  final VoidCallback onJoinRequest;
  final VoidCallback onManage;

  const _TeamCard({
    super.key,
    required this.team,
    required this.ownerInfo,
    required this.memberCount,
    required this.isOwner,
    required this.onViewDetails,
    required this.onJoinRequest,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final padding = context.isMobile ? 12.0 : 16.0;
    final logoSize = context.isMobile ? 50.0 : 60.0;
    final iconSize = ResponsiveUtils.getIconSize(context, 16.0);

    return Semantics(
      label: 'Team card for ${team.name}',
      hint: 'Tap to view team details or use buttons to join or manage',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Logo
              Center(
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: team.logo != null && team.logo!.isNotEmpty
                      ? CachedImage(
                          imageUrl: team.logo!,
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                          errorWidget: Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.groups,
                              color: Theme.of(context).colorScheme.primary,
                              size: logoSize * 0.5,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.groups,
                          color: Theme.of(context).colorScheme.primary,
                          size: logoSize * 0.5,
                        ),
                ),
              ),
              SizedBox(height: context.itemSpacing),

              // Team Name
              Text(
                team.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: context.isMobile ? 14 : 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.itemSpacing * 0.5),

              // Creator Name
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: iconSize,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ownerInfo['name'] ?? 'Unknown Owner',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                        fontSize: context.isMobile ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.itemSpacing * 0.25),

              // Number of Players
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: iconSize,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$memberCount / ${team.maxPlayers} players',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                      fontSize: context.isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.itemSpacing * 0.25),

              // Age Range
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: iconSize,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Age: ${team.minAge}–${team.maxAge}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                      fontSize: context.isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Buttons
              _buildResponsiveButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveButtons(BuildContext context) {
    final buttonHeight =
        context.buttonHeight * 0.8; // Slightly smaller for grid cards

    if (context.isMobile) {
      // Mobile: Stacked buttons
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: Semantics(
              label: 'View details for ${team.name}',
              hint: 'Open detailed information about this team',
              child: OutlinedButton(
                onPressed: onViewDetails,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: const Size(48, 48), // Minimum touch target
                ),
                child: Text(
                  LocalizationService().translate('view_details'),
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: isOwner
                ? Semantics(
                    label: 'Manage team ${team.name}',
                    hint: 'Open team management options',
                    child: ElevatedButton(
                      onPressed: onManage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(48, 48), // Minimum touch target
                      ),
                      child: Text(
                        LocalizationService().translate('manage_team'),
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final authProvider = context.read<AuthProvider>();
                      final userAge = authProvider.user?.age;
                      final canJoin = userAge == null ||
                          (userAge >= team.minAge && userAge <= team.maxAge);

                      return Semantics(
                        label: team.isRecruiting
                            ? canJoin
                                ? 'Request to join ${team.name}'
                                : 'Cannot join ${team.name} due to age restrictions'
                            : 'Team ${team.name} is not recruiting',
                        hint: team.isRecruiting
                            ? canJoin
                                ? 'Send a join request to this team'
                                : 'Your age (${userAge ?? 'unknown'}) is outside the team\'s age range (${team.minAge}–${team.maxAge})'
                            : 'This team is not currently accepting new members',
                        child: Tooltip(
                          message: canJoin
                              ? ''
                              : 'Age restriction: ${team.minAge}–${team.maxAge} years (your age: ${userAge ?? 'unknown'})',
                          child: ElevatedButton(
                            onPressed: (team.isRecruiting && canJoin) ? onJoinRequest : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(48, 48), // Minimum touch target
                              backgroundColor: (team.isRecruiting && canJoin)
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round()),
                            ),
                            child: Text(
                              team.isRecruiting
                                  ? canJoin
                                      ? LocalizationService().translate('request_to_join')
                                      : LocalizationService().translate('age_restricted')
                                  : LocalizationService().translate('not_recruiting_status'),
                              style: TextStyle(
                                fontSize: 11,
                                color: (team.isRecruiting && canJoin)
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    } else {
      // Tablet/Desktop: Side by side buttons
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: buttonHeight,
              child: Semantics(
                label: 'View details for ${team.name}',
                hint: 'Open detailed information about this team',
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(48, 48), // Minimum touch target
                  ),
                  child: Text(
                    LocalizationService().translate('view_details'),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: buttonHeight,
              child: isOwner
                  ? Semantics(
                      label: 'Manage team ${team.name}',
                      hint: 'Open team management options',
                      child: ElevatedButton(
                        onPressed: onManage,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size(
                            48,
                            48,
                          ), // Minimum touch target
                        ),
                        child: Text(
                          LocalizationService().translate('manage_team'),
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final authProvider = context.read<AuthProvider>();
                        final userAge = authProvider.user?.age;
                        final canJoin = userAge == null ||
                            (userAge >= team.minAge && userAge <= team.maxAge);

                        return Semantics(
                          label: team.isRecruiting
                              ? canJoin
                                  ? 'Request to join ${team.name}'
                                  : 'Cannot join ${team.name} due to age restrictions'
                              : 'Team ${team.name} is not recruiting',
                          hint: team.isRecruiting
                              ? canJoin
                                  ? 'Send a join request to this team'
                                  : 'Your age (${userAge ?? 'unknown'}) is outside the team\'s age range (${team.minAge}–${team.maxAge})'
                              : 'This team is not currently accepting new members',
                          child: Tooltip(
                            message: canJoin
                                ? ''
                                : 'Age restriction: ${team.minAge}–${team.maxAge} years (your age: ${userAge ?? 'unknown'})',
                            child: ElevatedButton(
                              onPressed: (team.isRecruiting && canJoin) ? onJoinRequest : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                minimumSize: const Size(
                                  48,
                                  48,
                                ), // Minimum touch target
                                backgroundColor: (team.isRecruiting && canJoin)
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round()),
                              ),
                              child: Text(
                                team.isRecruiting
                                    ? canJoin
                                        ? LocalizationService().translate('request_to_join')
                                        : LocalizationService().translate('age_restricted')
                                    : LocalizationService().translate('not_recruiting_status'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (team.isRecruiting && canJoin)
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      );
    }
  }
}
