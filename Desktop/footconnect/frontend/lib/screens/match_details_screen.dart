import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/match.dart';
import '../models/user.dart' as app_user;

class MatchDetailsScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final ApiService _apiService = ApiService();
  Match? _match;
  List<app_user.User> _players = [];
  bool _isLoading = true;
  bool _isLoadingPlayers = true;
  app_user.User? _currentUser;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMatchDetails();
    _loadMatchPlayers();
  }

  Future<void> _loadMatchDetails() async {
    try {
      final match = await _apiService.getMatch(widget.matchId);
      if (mounted) {
        setState(() {
          _match = match;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('failed_to_load_match')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // User not authenticated, that's okay
    }
  }

  Future<void> _loadMatchPlayers() async {
    try {
      final players = await _apiService.getMatchPlayers(widget.matchId);
      if (mounted) {
        setState(() {
          _players = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlayers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('failed_to_load_players')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _joinMatch() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService().translate('please_login_to_join')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      await _apiService.joinMatch(widget.matchId);
      // Reload players to show the user joined
      await _loadMatchPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('joined_match')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _leaveMatch() async {
    setState(() => _isJoining = true);

    try {
      await _apiService.leaveMatch(widget.matchId);
      // Reload players to show the user left
      await _loadMatchPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('left_match')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
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
        return Colors.purple;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('match_details')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _match == null
              ? Center(
                  child: Text(LocalizationService().translate('match_not_found')),
                )
              : SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // avoid null-assertion by promoting after an explicit null-check
                      final match = _match;
                      if (match == null) {
                        // Redundant safety: if _match is unexpectedly null show not-found placeholder
                        return Center(child: Text(LocalizationService().translate('match_not_found')));
                      }
                      return SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      // Match Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacitySafe(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sports_soccer,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              // Use fallback displayTitle when null
                              match.displayTitle,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(match.status).withOpacitySafe(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getLocalizedStatus(match.status),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _getStatusColor(match.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Match Details
                      Text(
                        LocalizationService().translate('match_information'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location
                      ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              // Use fallback when location is null
                              match.location,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                    ],

                      // Date & Time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            match.formattedDate,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Team
                      if (match.teamName != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              // teamName already guarded by the surrounding if; still provide safe fallback
                              match.teamName!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Match Type
                      Row(
                        children: [
                          Icon(
                            Icons.group_work,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            // Guard matchType and provide sensible default
                            match.matchType == 'mixed'
                                ? LocalizationService().translate('mixed')
                                : match.matchType == 'male'
                                    ? LocalizationService().translate('male')
                                    : LocalizationService().translate('female'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Max Players
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${LocalizationService().translate('max_players')}: ${match.defaultMaxPlayers}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.9),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      // Players Section
                      Text(
                        LocalizationService().translate('players'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _isLoadingPlayers
                          ? const Center(child: CircularProgressIndicator())
                          : _players.isEmpty
                              ? Center(
                                  child: Text(
                                    LocalizationService().translate('no_players_yet'),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _players.length,
                                  itemBuilder: (context, index) {
                                    final player = _players[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          child: Text(
                                            // Guard empty player name
                                            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(player.name),
                                        // Avoid using '!' on nullable position
                                        subtitle: player.position != null ? Text(player.position!) : null,
                                      ),
                                    );
                                  },
                                ),

                      const SizedBox(height: 32),

                      // Player Count Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacitySafe(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  _players.length.toString(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  LocalizationService().translate('joined'),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: Theme.of(context).colorScheme.outline.withOpacitySafe(0.3),
                            ),
                            Column(
                              children: [
                                Text(
                                  // compute remaining spots with safe fallback
                                  (match.defaultMaxPlayers - _players.length).toString(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                Text(
                                  LocalizationService().translate('spots_left'),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacitySafe(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Join/Leave Button
                      if (_currentUser != null && match.status == 'open') ...[
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isJoining ? null : (_players.any((player) => player.id == _currentUser!.id) ? _leaveMatch : _joinMatch),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _players.any((player) => player.id == _currentUser!.id)
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary,
                              foregroundColor: _players.any((player) => player.id == _currentUser!.id)
                                  ? Theme.of(context).colorScheme.onSecondary
                                  : Theme.of(context).colorScheme.onPrimary,
                              disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                              disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                              elevation: 4,
                              shadowColor: (_players.any((player) => player.id == _currentUser!.id)
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isJoining
                                ? SizedBox(
                                    height: 28,
                                    width: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _players.any((player) => player.id == _currentUser!.id)
                                            ? Theme.of(context).colorScheme.onSecondary
                                            : Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _players.any((player) => player.id == _currentUser!.id)
                                        ? LocalizationService().translate('leave_match')
                                        : LocalizationService().translate('join_match'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                           ],
                         ),
                       ),
                     ); // end SingleChildScrollView
                   }, // end Builder
                 ), // end LayoutBuilder
               ), // end SafeArea
     resizeToAvoidBottomInset: true, // Enable keyboard handling
   );
 }
}