import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/team.dart';
import '../services/localization_service.dart';
import '../widgets/cached_image.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final ApiService _apiService = ApiService();
  Team? _team;
  List<dynamic> _members = [];
  List<TeamJoinRequest> _joinRequests = [];
  List<TeamJoinRequest> _myJoinRequests = [];
  bool _isLoading = true;
  bool _isJoining = false;
  bool _isCancellingRequest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _loadTeamData();
    });
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final localContext = context;
      final localWidgetTeamId = widget.teamId;
      final authProvider = localContext.read<AuthProvider>();

      final team = await _apiService.getTeam(localWidgetTeamId);
      final members = await _apiService.getTeamMembers(localWidgetTeamId);

      final isOwner = authProvider.user?.id == team.ownerId;

      // Load join requests if user is the owner
      List<TeamJoinRequest> joinRequests = [];
      if (isOwner) {
        try {
          joinRequests = (await _apiService.getTeamJoinRequests(
            localWidgetTeamId,
          )).cast<TeamJoinRequest>();
        } catch (e) {
          // Silently fail for join requests - not critical for team display
        }
      }

      // Load user's join requests to check for pending requests to this team
      List<TeamJoinRequest> myJoinRequests = [];
      try {
        myJoinRequests = await _apiService.getMyJoinRequests();
      } catch (e) {
        // Silently fail for user's join requests - not critical for team display
      }

      if (!mounted) return;
      setState(() {
        _team = team;
        _members = members;
        _joinRequests = joinRequests;
        _myJoinRequests = myJoinRequests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService().translate('error')}: $e'),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showJoinRequestDialog() async {
    final TextEditingController messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate('join_team')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${LocalizationService().translate('join_team_request_message')} "${_team!.name}"',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate(
                    'message_optional',
                  ),
                  hintText: LocalizationService().translate(
                    'enter_message_hint',
                  ),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
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
              child: Text(LocalizationService().translate('send_request')),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _joinTeam(
        messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
      );
    }
  }

  Future<void> _joinTeam([String? message]) async {
    if (_team == null) return;

    setState(() {
      _isJoining = true;
    });

    try {
      await _apiService.createJoinRequest(widget.teamId, message: message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('join_request_sent')),
          ),
        );
        // Reload data to update UI
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  Future<void> _cancelJoinRequest() async {
    final pendingRequest = _getPendingRequestForCurrentTeam();
    if (pendingRequest == null) return;

    setState(() {
      _isCancellingRequest = true;
    });

    try {
      await _apiService.cancelJoinRequest(widget.teamId, pendingRequest.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('join_request_cancelled'),
            ),
          ),
        );
        // Reload data to update UI
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isCancellingRequest = false;
      });
    }
  }

  TeamJoinRequest? _getPendingRequestForCurrentTeam() {
    return _myJoinRequests.cast<TeamJoinRequest?>().firstWhere(
      (request) =>
          request?.team?.id == widget.teamId && request?.status == 'pending',
      orElse: () => null,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isOwner = authProvider.user?.id == _team?.ownerId;
    final isMember = _members.any(
      (member) => member.id == authProvider.user?.id,
    );
    final hasPendingRequest = _getPendingRequestForCurrentTeam() != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _team?.name ?? LocalizationService().translate('team_details'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teams'),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/teams/${widget.teamId}/manage'),
            ),
        ],
      ),
      body: _isLoading
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
                  // Team Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child:
                                    _team!.logo != null &&
                                        _team!.logo!.isNotEmpty
                                    ? CachedImage(
                                        imageUrl: _team!.logo!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(12),
                                        errorWidget: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha((0.1 * 255).round()),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.groups,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 30,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.groups,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 30,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${LocalizationService().translate('members')}: ${_members.length}/${_team!.maxPlayers}',
                              ),
                            ],
                          ),
                          if (_team!.description != null &&
                              _team!.description!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              _team!.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Owner and Creation Info
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${LocalizationService().translate('owner')}: ${_team!.owner!.name}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${LocalizationService().translate('created')}: ${_formatDate(_team!.createdAt)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  if (!isOwner &&
                      !isMember &&
                      !hasPendingRequest &&
                      _team!.isRecruiting)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isJoining ? null : _showJoinRequestDialog,
                        child: _isJoining
                            ? const CircularProgressIndicator()
                            : Text(
                                LocalizationService().translate('join_team'),
                              ),
                      ),
                    )
                  else if (hasPendingRequest)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isCancellingRequest
                            ? null
                            : _cancelJoinRequest,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        child: _isCancellingRequest
                            ? const CircularProgressIndicator()
                            : Text(
                                LocalizationService().translate(
                                  'cancel_request',
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                      ),
                    )
                  else if (isMember)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        LocalizationService().translate('already_member'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else if (isOwner)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        LocalizationService().translate('team_owner'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Team Members
                  Text(
                    LocalizationService().translate('team_members'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  _members.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              LocalizationService().translate('no_members'),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final isCurrentUser =
                                member.id == authProvider.user?.id;

                            return Card(
                              key: ValueKey(
                                member.id,
                              ), // Add unique key for each member card
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: member.role == 'admin'
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                    member.name
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '?',
                                    style: TextStyle(
                                      color: member.role == 'admin'
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
                                        member.name ??
                                            LocalizationService().translate(
                                              'unknown_user',
                                            ),
                                        style: TextStyle(
                                          fontWeight: isCurrentUser
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (member.role == 'admin')
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'ADMIN',
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
                                      member.role == 'admin'
                                          ? LocalizationService().translate(
                                              'team_admin',
                                            )
                                          : LocalizationService().translate(
                                              'team_member',
                                            ),
                                      style: TextStyle(
                                        color: member.role == 'admin'
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withAlpha((0.7 * 255).round()),
                                      ),
                                    ),
                                    if (member.position != null &&
                                        member.position!.isNotEmpty)
                                      Text(
                                        'Position: ${member.position}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                                trailing: isCurrentUser
                                    ? Icon(
                                        Icons.person,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),

                  // Join Requests Section (for team owners only)
                  if (isOwner && _joinRequests.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Join Requests (${_joinRequests.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _joinRequests.length,
                      itemBuilder: (context, index) {
                        final request = _joinRequests[index];
                        final user = request.user;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      child: Text(
                                        user?.name
                                                .substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user?.name ?? 'Unknown User',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          Text(
                                            user?.email ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withAlpha((0.7 * 255).round()),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withAlpha((0.1 * 255).round()),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (request.message != null &&
                                    request.message!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '"${request.message}"',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _rejectJoinRequest(request.id),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
                                        child: Text(
                                          'Reject',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _acceptJoinRequest(request.id),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _acceptJoinRequest(String requestId) async {
    try {
      await _apiService.updateJoinRequestStatus(
        widget.teamId,
        requestId,
        'approved',
      );
      await _loadTeamData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Join request accepted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
      }
    }
  }

  Future<void> _rejectJoinRequest(String requestId) async {
    try {
      await _apiService.updateJoinRequestStatus(
        widget.teamId,
        requestId,
        'rejected',
      );
      await _loadTeamData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Join request rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting request: $e')));
      }
    }
  }
}
