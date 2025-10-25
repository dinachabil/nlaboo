import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService().translate('theme'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<ThemeMode>(
                        segments: ThemeMode.values.map((mode) => ButtonSegment<ThemeMode>(
                          value: mode,
                          label: Text(_getThemeModeName(mode, themeProvider)),
                        )).toList(),
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (selected) => themeProvider.setThemeMode(selected.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Language Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService().translate('language'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment<String>(
                            value: 'en',
                            label: Text(LocalizationService().translate('english')),
                          ),
                          ButtonSegment<String>(
                            value: 'fr',
                            label: Text(LocalizationService().translate('french')),
                          ),
                          ButtonSegment<String>(
                            value: 'ar',
                            label: Text(LocalizationService().translate('arabic')),
                          ),
                        ],
                        selected: {LocalizationService().currentLanguage},
                        onSelectionChanged: (selected) async {
                          final value = selected.first;
                          await LocalizationService().loadLanguage(value);
                          // Force rebuild to show new language
                          if (context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService().translate('account'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () => _showLogoutConfirmation(context),
                          icon: const Icon(Icons.logout),
                          label: Text(
                            LocalizationService().translate('logout'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                            elevation: 4,
                            shadowColor: Theme.of(context).colorScheme.error.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode, ThemeProvider themeProvider) {
    switch (mode) {
      case ThemeMode.system:
        return LocalizationService().translate('system_mode');
      case ThemeMode.light:
        return LocalizationService().translate('light_mode');
      case ThemeMode.dark:
        return LocalizationService().translate('dark_mode');
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(LocalizationService().translate('logout')),
          content: Text(LocalizationService().translate('logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(LocalizationService().translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(LocalizationService().translate('logout')),
            ),
          ],
        );
      },
    );
  }
}