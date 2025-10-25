import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../services/api_service.dart';
import '../models/match.dart';
import '../services/localization_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = 'all'; // 'all', 'open', 'closed', 'my-matches'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchProvider = context.read<MatchProvider>();
      matchProvider.loadAllMatches();
    });
  }

  Future<void> _closeMatch(String matchId) async {
    try {
      final matchProvider = context.read<MatchProvider>();
      await _apiService.closeMatch(matchId);
      // Real-time updates will handle the UI refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match closed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error closing match: $e')));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'open':
        backgroundColor = Colors.green.withAlpha((0.1 * 255).round());
        textColor = Colors.green;
        text = 'Open';
        break;
      case 'closed':
        backgroundColor = Colors.red.withAlpha((0.1 * 255).round());
        textColor = Colors.red;
        text = 'Closed';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withAlpha((0.1 * 255).round());
        textColor = Colors.orange;
        text = 'Pending';
        break;
      default:
        backgroundColor = Colors.grey.withAlpha((0.1 * 255).round());
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.user?.role == 'admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/match/${match.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusBadge(match.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      match.location,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match.formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${match.maxPlayers ?? 22} players',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (match.team1Name != null && match.team2Name != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.team1Name!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        match.team2Name!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
              if (isAdmin && match.isOpen) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _closeMatch(match.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Close Match'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final matchProvider = context.watch<MatchProvider>();
    final hasTeam = authProvider.isAuthenticated;

    // Apply filter to matches
    List<Match> filteredMatches = matchProvider.matches;
    if (_selectedFilter == 'open') {
      filteredMatches = filteredMatches.where((match) => match.isOpen).toList();
    } else if (_selectedFilter == 'closed') {
      filteredMatches = filteredMatches.where((match) => match.isClosed).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('matches')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => matchProvider.loadAllMatches(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = 'all');
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Open'),
                  selected: _selectedFilter == 'open',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = 'open');
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Closed'),
                  selected: _selectedFilter == 'closed',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = 'closed');
                    }
                  },
                ),
                if (authProvider.isAuthenticated) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('My Matches'),
                    selected: _selectedFilter == 'my-matches',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'my-matches');
                        // TODO: Implement my matches filter
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: matchProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matches found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMatches.length,
                    itemBuilder: (context, index) =>
                        _buildMatchCard(filteredMatches[index]),
                  ),
          ),
        ],
      ),

      // FAB for creating matches (only if user has a team)
      floatingActionButton: hasTeam
          ? FloatingActionButton(
              onPressed: () => context.push('/create-match'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
