import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/match.dart';
import '../models/team.dart';
import '../models/user.dart' as app_user;
import '../utils/responsive_utils.dart';
import '../constants/translation_keys.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Match> _allMatches = [];
  List<Team> _allTeams = [];
  List<Match> _featuredMatches = [];
  List<Team> _featuredTeams = [];
  bool _isLoading = true;
  bool _isUserInTeam = false;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      // Load featured matches and teams
      final matches = await _apiService.getMatches();
      final teams = await _apiService.getAllTeams();

      // Check if user is in a team
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final isInTeam = await _checkUserTeamMembership(authProvider.user);

      if (mounted) {
        setState(() {
          _allMatches = matches;
          _allTeams = teams;
          _isUserInTeam = isInTeam;
          _isLoading = false;
        });
        _filterContent();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate(TranslationKeys.failedToLoad)}: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterContent() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _featuredMatches = _allMatches.take(3).toList();
        _featuredTeams = _allTeams.take(3).toList();
      });
      return;
    }

    final query = _searchQuery.toLowerCase();
    final filteredMatches = _allMatches.where((match) {
      return match.title?.toLowerCase().contains(query) == true ||
          match.location.toLowerCase().contains(query);
    }).toList();

    final filteredTeams = _allTeams.where((team) {
      return team.name.toLowerCase().contains(query) ||
          (team.location?.toLowerCase().contains(query) == true);
    }).toList();

    setState(() {
      _featuredMatches = filteredMatches.take(6).toList();
      _featuredTeams = filteredTeams.take(6).toList();
    });
  }

  Future<bool> _checkUserTeamMembership(app_user.User? user) async {
    if (user == null) return false;
    try {
      final teams = await _apiService.getMyTeams();
      return teams.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Removed unused method: _getLocalizedStatus

  // Removed unused method: _getStatusColor

  @override
  Widget build(BuildContext context) {

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Access Buttons
                _buildQuickActionButtons(context),
                SizedBox(height: context.itemSpacing),

                // Featured Matches Section
                _buildSectionHeader(
                  LocalizationService().translate(TranslationKeys.featuredMatches),
                  () => context.go('/matches'),
                ),
                SizedBox(height: context.itemSpacing),
                _buildFeaturedMatches(),

                SizedBox(height: context.itemSpacing * 2),

                // Featured Teams Section
                _buildSectionHeader(
                  LocalizationService().translate(TranslationKeys.featuredTeams),
                  () => context.go('/teams'),
                ),
                SizedBox(height: context.itemSpacing),
                _buildFeaturedTeams(),
              ],
            ),
          );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      // Desktop: Side by side buttons
      return Row(
        children: [
          if (!_isUserInTeam)
            Expanded(
              child: Semantics(
                label: LocalizationService().translate(TranslationKeys.createTeam),
                hint: 'Create a new team to organize football matches',
                child: _QuickActionButton(
                  icon: Icons.group_add,
                  label: LocalizationService().translate(TranslationKeys.createTeam),
                  onPressed: () => context.go('/create-team'),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          if (_isUserInTeam) ...[
            if (!_isUserInTeam) SizedBox(width: context.itemSpacing),
            Expanded(
              child: Semantics(
                label: LocalizationService().translate(TranslationKeys.createMatch),
                hint: 'Create a new football match for your team',
                child: _QuickActionButton(
                  icon: Icons.add,
                  label: LocalizationService().translate(TranslationKeys.createMatch),
                  onPressed: () => context.go('/create-match'),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      // Mobile/Tablet: Stacked buttons
      return Column(
        children: [
          if (!_isUserInTeam)
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight,
              child: Semantics(
                label: LocalizationService().translate(TranslationKeys.createTeam),
                hint: 'Create a new team to organize football matches',
                child: _QuickActionButton(
                  icon: Icons.group_add,
                  label: LocalizationService().translate(TranslationKeys.createTeam),
                  onPressed: () => context.go('/create-team'),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          if (_isUserInTeam) ...[
            if (!_isUserInTeam) SizedBox(height: context.itemSpacing),
            SizedBox(
              width: double.infinity,
              height: context.buttonHeight,
              child: Semantics(
                label: LocalizationService().translate(TranslationKeys.createMatch),
                hint: 'Create a new football match for your team',
                child: _QuickActionButton(
                  icon: Icons.add,
                  label: LocalizationService().translate(TranslationKeys.createMatch),
                  onPressed: () => context.go('/create-match'),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Semantics(
          label: 'View all $title',
          hint: 'Navigate to see complete list of $title',
          child: TextButton(
            onPressed: onViewAll,
            child: Text(LocalizationService().translate(TranslationKeys.viewAll)),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedMatches() {
    if (_featuredMatches.isEmpty) {
      return _buildEmptyState(
        LocalizationService().translate(TranslationKeys.noFeaturedMatchesAvailable),
      );
    }

    final cardHeight = context.isMobile ? 200.0 : 220.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        key: const PageStorageKey('featured_matches'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.itemSpacing),
        itemCount: _featuredMatches.length,
        itemBuilder: (context, index) {
          final match = _featuredMatches[index];
          return Padding(
            padding: EdgeInsets.only(right: context.itemSpacing),
            child: _MatchCard(key: ValueKey(match.id), match: match),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedTeams() {
    if (_featuredTeams.isEmpty) {
      return _buildEmptyState(
        LocalizationService().translate(TranslationKeys.noFeaturedTeamsAvailable),
      );
    }

    final cardHeight = context.isMobile ? 180.0 : 200.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        key: const PageStorageKey('featured_teams'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.itemSpacing),
        itemCount: _featuredTeams.length,
        itemBuilder: (context, index) {
          final team = _featuredTeams[index];
          return Padding(
            padding: EdgeInsets.only(right: context.itemSpacing),
            child: _TeamCard(key: ValueKey(team.id), team: team),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}

// Match Card Widget
class _MatchCard extends StatelessWidget {
  final Match match;

  const _MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final cardWidth = ResponsiveUtils.getCardWidth(context, maxWidth: 320.0);
    final iconSize = ResponsiveUtils.getIconSize(context, 20.0);
    final padding = context.isMobile ? 12.0 : 16.0;

    return Semantics(
      label: 'Match: ${match.displayTitle}',
      hint: 'Tap to view match details and join the game',
      child: SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => context.go('/match/${match.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match Icon and Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.sports_soccer,
                          color: Theme.of(context).colorScheme.primary,
                          size: iconSize,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(match.status).withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          getLocalizedStatus(match.status),
                          style: TextStyle(
                            color: getStatusColor(match.status),
                            fontSize: context.isMobile ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.itemSpacing),

                  // Match Title
                  Text(
                    match.displayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: context.isMobile ? 14 : 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.itemSpacing * 0.5),

                  // Location and Date
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: context.isMobile ? 14 : 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          match.location,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: context.isMobile ? 14 : 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.formattedDate,
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

                  // Players Count
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: context.isMobile ? 14 : 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${match.defaultMaxPlayers} players',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                          fontSize: context.isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper functions for MatchCard
String getLocalizedStatus(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return LocalizationService().translate(TranslationKeys.open);
    case 'closed':
      return LocalizationService().translate(TranslationKeys.closed);
    default:
      return status;
  }
}

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return Colors.green;
    case 'closed':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Team Card Widget
class _TeamCard extends StatelessWidget {
  final Team team;

  const _TeamCard({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final cardWidth = ResponsiveUtils.getCardWidth(context, maxWidth: 280.0);
    final iconSize = ResponsiveUtils.getIconSize(context, 20.0);
    final padding = context.isMobile ? 12.0 : 16.0;

    return Semantics(
      label: 'Team: ${team.name}',
      hint: 'Tap to view team details and join options',
      child: SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => context.go('/teams/${team.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Icon and Recruiting Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.groups,
                          color: Theme.of(context).colorScheme.secondary,
                          size: iconSize,
                        ),
                      ),
                      const Spacer(),
                      if (team.isRecruiting)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            LocalizationService().translate(
                              TranslationKeys.recruiting,
                            ),
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: context.isMobile ? 9 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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

                  // Location
                  if (team.location != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: context.isMobile ? 14 : 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            team.location!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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

                  const Spacer(),

                  // Max Players
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: context.isMobile ? 14 : 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Max ${team.maxPlayers} players',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                          fontSize: context.isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
