import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/team.dart';
import '../services/localization_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final ApiService _apiService = ApiService();
  List<Team> _teams = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teams = await _apiService.getAllTeams();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocalizationService().translate('error')}: $e')),
        );
      }
    }
  }

  Future<void> _searchTeams(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      if (query.isEmpty) {
        await _loadTeams();
      } else {
        final teams = await _apiService.searchTeams(query);
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocalizationService().translate('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final isMediumScreen = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('teams')),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              width: isLargeScreen ? constraints.maxWidth * 0.8 : (isMediumScreen ? constraints.maxWidth * 0.9 : double.infinity),
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: LocalizationService().translate('search_teams'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: _searchTeams,
                    ),
                  ),

                  // Teams List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _teams.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? LocalizationService().translate('no_teams_found')
                                      : LocalizationService().translate('no_teams_match_search'),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: _teams.length,
                                itemBuilder: (context, index) {
                                  final team = _teams[index];
                                  final isOwner = authProvider.user?.id == team.ownerId;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        child: team.logo != null
                                            ? null // TODO: Add image loading
                                            : Text(
                                                team.name.substring(0, 1).toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                      title: Text(
                                        team.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (team.location != null) Text(team.location!),
                                          Text('${LocalizationService().translate('max_players')}: ${team.maxPlayers}'),
                                          Text(
                                            team.isRecruiting
                                                ? LocalizationService().translate('recruiting')
                                                : LocalizationService().translate('not_recruiting'),
                                            style: TextStyle(
                                              color: team.isRecruiting
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: isOwner
                                          ? IconButton(
                                              icon: const Icon(Icons.settings),
                                              onPressed: () => _showTeamManagement(context, team),
                                            )
                                          : team.isRecruiting
                                              ? ElevatedButton(
                                                  onPressed: () => _showJoinRequestDialog(context, team),
                                                  child: Text(LocalizationService().translate('join_team')),
                                                )
                                              : null,
                                      onTap: () => _showTeamDetails(context, team),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-team'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTeamDetails(BuildContext context, Team team) {
    // TODO: Navigate to team details screen
    context.push('/teams/${team.id}');
  }

  void _showTeamManagement(BuildContext context, Team team) {
    // TODO: Navigate to team management screen
    context.push('/teams/${team.id}/manage');
  }

  void _showJoinRequestDialog(BuildContext context, Team team) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${LocalizationService().translate('join_team')} ${team.name}'),
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
                await _apiService.createJoinRequest(
                  team.id,
                  message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocalizationService().translate('join_request_sent'))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${LocalizationService().translate('error')}: $e')),
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