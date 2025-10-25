import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated || authProvider.user?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.admin),
        ),
        body: Center(
          child: Text(l10n.adminOnly),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admin),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.admin,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome Admin: ${authProvider.user!.email}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text('Admin Dashboard - Manage users and matches here'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => authProvider.logout(),
              child: Text(l10n.logout),
            ),
          ],
        ),
      ),
    );
  }
}