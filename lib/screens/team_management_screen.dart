import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/team.dart';
import '../services/localization_service.dart';

class TeamManagementScreen extends StatefulWidget {
  final String teamId;

  const TeamManagementScreen({super.key, required this.teamId});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final ApiService _apiService = ApiService();
  Team? _team;
  List<TeamJoinRequest> _joinRequests = [];
  bool _isLoading = true;
  bool _isTogglingRecruiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final team = await _apiService.getTeam(widget.teamId);
      final joinRequests = await _apiService.getTeamJoinRequests(widget.teamId);

      setState(() {
        _team = team;
        _joinRequests = joinRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _toggleRecruiting() async {
    if (_team == null) return;

    setState(() {
      _isTogglingRecruiting = true;
    });

    try {
      await _apiService.toggleTeamRecruiting(widget.teamId);

      // Reload team data to get updated recruiting status
      await _loadData();

      setState(() {
        _isTogglingRecruiting = false;
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _team!.isRecruiting
                      ? LocalizationService().translate('recruiting_enabled')
                      : LocalizationService().translate('recruiting_disabled'),
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isTogglingRecruiting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _updateJoinRequestStatus(String requestId, String status) async {
    try {
      await _apiService.updateJoinRequestStatus(
        widget.teamId,
        requestId,
        status,
      );

      // Update local state
      setState(() {
        _joinRequests = _joinRequests.map((request) {
          if (request.id == requestId) {
            return request.copyWith(status: status);
          }
          return request;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? LocalizationService().translate('request_approved')
                  : LocalizationService().translate('request_rejected'),
            ),
          ),
        );
      }

      // Reload data to get updated member count
      await _loadData();
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

  Future<void> _showDeleteTeamDialog() async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate('delete_team')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocalizationService().translate('delete_team_confirmation')),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('reason_optional'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
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
              child: Text(LocalizationService().translate('delete')),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteTeam(reasonController.text.trim());
    }
  }

  Future<void> _deleteTeam(String reason) async {
    try {
      await _apiService.deleteTeam(
        widget.teamId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('team_deleted_successfully'),
            ),
          ),
        );
        context.go('/teams'); // Navigate back to teams list
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${LocalizationService().translate('error')}: $e'),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final isMediumScreen = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _team?.name ?? LocalizationService().translate('team_management'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              width: isLargeScreen
                  ? constraints.maxWidth * 0.8
                  : (isMediumScreen
                        ? constraints.maxWidth * 0.9
                        : double.infinity),
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _team == null
                  ? Center(
                      child: Text(
                        LocalizationService().translate('team_not_found'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Team Info Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        child: Text(
                                          _team!.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _team!.name,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.headlineSmall,
                                            ),
                                            if (_team!.location != null)
                                              Text(_team!.location!),
                                            Text(
                                              '${LocalizationService().translate('max_players')}: ${_team!.maxPlayers}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        _team!.isRecruiting
                                            ? LocalizationService().translate(
                                                'recruiting',
                                              )
                                            : LocalizationService().translate(
                                                'not_recruiting',
                                              ),
                                        style: TextStyle(
                                          color: _team!.isRecruiting
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      _isTogglingRecruiting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Switch(
                                              value: _team!.isRecruiting,
                                              onChanged: (_) =>
                                                  _toggleRecruiting(),
                                            ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.go(
                                            '/create-match?team1=${widget.teamId}',
                                          ),
                                          icon: const Icon(Icons.add),
                                          label: Text(
                                            LocalizationService().translate(
                                              'create_match',
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _showDeleteTeamDialog(),
                                        icon: const Icon(Icons.delete),
                                        label: Text(
                                          LocalizationService().translate(
                                            'delete_team',
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.onError,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Join Requests Section
                          Text(
                            LocalizationService().translate('join_requests'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),

                          _joinRequests.isEmpty
                              ? Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      LocalizationService().translate(
                                        'no_join_requests',
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _joinRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = _joinRequests[index];

                                    return Card(
                                      margin: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  child: Text(
                                                    request.user?.name
                                                            .substring(0, 1)
                                                            .toUpperCase() ??
                                                        '?',
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        request.user?.name ??
                                                            LocalizationService()
                                                                .translate(
                                                                  'unknown_user',
                                                                ),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${LocalizationService().translate('requested')}: ${request.createdAt.toString().split(' ')[0]}',
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        request.status ==
                                                            'pending'
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                        : request.status ==
                                                              'approved'
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    request.status
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (request.message != null &&
                                                request
                                                    .message!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                '"${request.message}"',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                              ),
                                            ],
                                            if (request.status ==
                                                'pending') ...[
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        _updateJoinRequestStatus(
                                                          request.id,
                                                          'rejected',
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                    ),
                                                    child: Text(
                                                      LocalizationService()
                                                          .translate('reject'),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        _updateJoinRequestStatus(
                                                          request.id,
                                                          'approved',
                                                        ),
                                                    child: Text(
                                                      LocalizationService()
                                                          .translate('approve'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
