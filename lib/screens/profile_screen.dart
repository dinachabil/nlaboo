import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../services/localization_service.dart';
import '../models/user.dart' as app_user;
import '../models/team.dart';
import '../widgets/cached_image.dart';
import '../config/supabase_config.dart';
import '../utils/responsive_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userStats = {};
  bool _isLoadingStats = false;
  app_user.User? _currentUser;
  bool _isLoadingUser = false;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserStats();
    // User teams will be loaded via TeamProvider real-time updates
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load user data if we don't have it yet (first time)
    if (_currentUser == null && !_isLoadingUser) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Use AuthProvider's refreshUser method which handles API calls internally
      await authProvider.refreshUser();

      if (mounted && !_isDisposed) {
        setState(() {
          _currentUser = authProvider.user;
          _isLoadingUser = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      // Fall back to cached user data from AuthProvider
      if (!mounted || _isDisposed) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _currentUser = authProvider.user;
            _isLoadingUser = false;
            _errorMessage =
                'Using cached data. Some information may be outdated.';
          });
        }
      } else {
        // No cached data available
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoadingUser = false;
            _errorMessage =
                'Failed to load profile data. Please check your connection and try again.';
          });
        }
      }
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final stats = await authProvider.getUserStats();
      if (mounted && !_isDisposed) {
        setState(() => _userStats = stats);
      }
    } catch (e) {
      // Silently fail for stats loading - not critical for profile display
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _leaveTeam(String teamId) async {
    try {
      // Auth token is now handled automatically by Supabase client

      // Use the leave team endpoint
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/teams/$teamId/leave'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Real-time updates will handle the UI refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationService().translate('left_team_successfully'),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to leave team: ${response.body}');
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



  Future<void> _showLeaveTeamDialog(Team team) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${LocalizationService().translate('leave_team')} ${team.name}',
          ),
          content: Text(
            LocalizationService().translate('leave_team_confirmation'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(LocalizationService().translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(LocalizationService().translate('leave')),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _leaveTeam(team.id);
    }
  }


  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacitySafe(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacitySafe(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = context.watch<TeamProvider>();

    // Show loading while user data is being fetched
    if (_isLoadingUser) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    // Show error if loading failed
    if (_errorMessage != null && _currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // If we have an error but also have cached user data, show the data with a warning
    if (_errorMessage != null && _currentUser != null) {
      // Show a banner warning about using cached data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Using cached profile data. Some information may be outdated.',
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Refresh',
                onPressed: _loadUserData,
              ),
            ),
          );
        }
      });
    }

    // At this point, we should have user data
    if (_currentUser == null) {
      return const Center(child: Text('No user data available'));
    }

    final user = _currentUser!;

    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar Section
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: user.imageUrl != null
                ? CachedCircleImage(
                    imageUrl: user.imageUrl!,
                    radius: context.isMobile ? 50 : 60,
                  )
                : CircleAvatar(
                    radius: context.isMobile ? 50 : 60,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.person,
                      size: context.isMobile ? 32 : 40,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
          ),

          SizedBox(height: context.itemSpacing * 2),

          // User Name
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: context.isMobile ? 24 : 28,
            ),
          ),

          if (user.position != null && user.position!.isNotEmpty) ...[
            SizedBox(height: context.itemSpacing * 0.5),
            Text(
              user.position!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: context.isMobile ? 16 : 18,
              ),
            ),
          ],

          if (user.bio != null && user.bio!.isNotEmpty) ...[
            SizedBox(height: context.itemSpacing),
            Container(
              constraints: BoxConstraints(maxWidth: context.maxContentWidth),
              child: Text(
                user.bio!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacitySafe(0.8),
                  fontSize: context.isMobile ? 14 : 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          SizedBox(height: context.itemSpacing * 3),

          // User Info (Read-only)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService().translate('account_info'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: context.isMobile ? 16 : 18,
                    ),
                  ),
                  SizedBox(height: context.itemSpacing),
                  _buildInfoRow(
                    LocalizationService().translate('full_name'),
                    user.name,
                  ),
                  _buildInfoRow(
                    LocalizationService().translate('email'),
                    user.email,
                  ),
                  _buildInfoRow(
                    LocalizationService().translate('teams_owned'),
                    teamProvider.userTeams
                        .where((team) => team.ownerId == user.id)
                        .length
                        .toString(),
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    _buildInfoRow(
                      LocalizationService().translate('phone'),
                      user.phone!,
                    ),
                  if (user.age != null)
                    _buildInfoRow(
                      LocalizationService().translate('age'),
                      user.age.toString(),
                    ),
                  if (user.gender != null)
                    _buildInfoRow(
                      LocalizationService().translate('gender'),
                      user.gender == 'male'
                          ? LocalizationService().translate('male')
                          : LocalizationService().translate('female'),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.itemSpacing * 2),

          // User Statistics
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService().translate('user_stats'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: context.isMobile ? 16 : 18,
                    ),
                  ),
                  SizedBox(height: context.itemSpacing),
                  if (_isLoadingStats)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Container(
                      padding: EdgeInsets.all(context.isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: _buildStatRow(
                        LocalizationService().translate('matches_joined'),
                        _userStats['matches_joined']?.toString() ?? '0',
                        Icons.sports_soccer,
                      ),
                    ),
                    SizedBox(height: context.itemSpacing),
                    Container(
                      padding: EdgeInsets.all(context.isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: _buildStatRow(
                        LocalizationService().translate('matches_created'),
                        _userStats['matches_created']?.toString() ?? '0',
                        Icons.add_circle,
                      ),
                    ),
                    SizedBox(height: context.itemSpacing),
                    Container(
                      padding: EdgeInsets.all(context.isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiary.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: _buildStatRow(
                        LocalizationService().translate('teams_owned'),
                        _userStats['teams_owned']?.toString() ?? '0',
                        Icons.group,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: context.itemSpacing * 2),

          // My Teams Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocalizationService().translate('my_teams'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: context.isMobile ? 16 : 18,
                            ),
                      ),
                      if (!context.isMobile)
                        TextButton.icon(
                          onPressed: () => context.go('/teams'),
                          icon: const Icon(Icons.group_add),
                          label: Text(
                            LocalizationService().translate('view_all_teams'),
                          ),
                        ),
                    ],
                  ),
                  if (context.isMobile)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.go('/teams'),
                        icon: const Icon(Icons.group_add),
                        label: Text(
                          LocalizationService().translate('view_all_teams'),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  SizedBox(height: context.itemSpacing),
                  if (teamProvider.userTeams.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.group_off,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(128),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationService().translate('no_teams_yet'),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(179),
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/create-team'),
                            icon: const Icon(Icons.add),
                            label: Text(
                              LocalizationService().translate('create_team'),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teamProvider.userTeams.length,
                      itemBuilder: (context, index) {
                        final team = teamProvider.userTeams[index];
                        final isOwner = team.ownerId == _currentUser?.id;

                        return Card(
                          key: ValueKey(
                            team.id,
                          ), // Add unique key for each team card
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              border: isOwner
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isOwner
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                                child: team.logo != null
                                    ? CachedImage(
                                        imageUrl: team.logo!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(20),
                                      )
                                    : Text(
                                        team.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: isOwner
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      team.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isOwner
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (isOwner)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        LocalizationService().translate(
                                          'your_team',
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOwner
                                        ? LocalizationService().translate(
                                            'team_owner_manage',
                                          )
                                        : LocalizationService().translate(
                                            'team_member_text',
                                          ),
                                    style: TextStyle(
                                      color: isOwner
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha((0.7 * 255).round()),
                                      fontWeight: isOwner
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (team.location != null)
                                    Text(team.location!),
                                  Text(
                                    '${LocalizationService().translate('max_players')}: ${team.maxPlayers}',
                                  ),
                                  Text(
                                    team.isRecruiting
                                        ? LocalizationService().translate(
                                            'recruiting',
                                          )
                                        : LocalizationService().translate(
                                            'not_recruiting',
                                          ),
                                    style: TextStyle(
                                      color: team.isRecruiting
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isOwner
                                  ? IconButton(
                                      icon: const Icon(Icons.settings),
                                      onPressed: () => context.go(
                                        '/teams/${team.id}/manage',
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.exit_to_app),
                                      onPressed: () =>
                                          _showLeaveTeamDialog(team),
                                    ),
                              onTap: () => context.go('/teams/${team.id}'),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.itemSpacing * 3),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            height: context.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/edit-profile'),
              icon: const Icon(Icons.edit),
              label: Text(
                LocalizationService().translate('edit_profile'),
                style: TextStyle(
                  fontSize: context.isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 4,
                shadowColor: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(77),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          SizedBox(height: context.itemSpacing),

          // Admin Dashboard Button (only for admins)
          if (user.isAdmin) ...[
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings),
                label: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: context.isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  elevation: 4,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.error.withAlpha(77),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.itemSpacing),
          ],
        ],
      ),
    );
  }
}
