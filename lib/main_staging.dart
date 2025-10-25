import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nlaabo/config/build_config.dart';
import 'package:nlaabo/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:nlaabo/providers/auth_provider.dart';
import 'package:nlaabo/screens/auth_landing_screen.dart';
import 'package:nlaabo/screens/home_screen.dart';
import 'package:nlaabo/screens/profile_screen.dart';
import 'package:nlaabo/screens/edit_profile_screen.dart';
import 'package:nlaabo/screens/create_match_screen.dart';
import 'package:nlaabo/screens/create_team_screen.dart';
import 'package:nlaabo/screens/admin_dashboard_screen.dart';
import 'package:nlaabo/screens/settings_screen.dart';
import 'package:nlaabo/screens/notifications_screen.dart';
import 'package:nlaabo/screens/match_details_screen.dart';
import 'package:nlaabo/screens/teams_screen.dart';
import 'package:nlaabo/screens/team_details_screen.dart';
import 'package:nlaabo/screens/team_management_screen.dart';
import 'package:nlaabo/screens/matches_screen.dart';
import 'package:nlaabo/screens/auth_callback_screen.dart';
import 'package:nlaabo/widgets/main_layout.dart';

final GoRouter router = GoRouter(
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Public routes that don't require authentication
    final publicRoutes = ['/auth', '/auth-callback'];

    // Get the current location
    final currentLocation = state.uri.path;

    // If user is not authenticated and trying to access protected route
    if (!authProvider.isAuthenticated &&
        !publicRoutes.contains(currentLocation)) {
      return '/auth';
    }

    // If user is authenticated and trying to access auth, redirect to home
    if (authProvider.isAuthenticated &&
        publicRoutes.contains(currentLocation)) {
      return '/home';
    }

    // Admin route protection
    if (currentLocation == '/admin' && authProvider.user?.role != 'admin') {
      return '/home';
    }

    // Allow authenticated users to create matches (players can organize pickup games)
    if (currentLocation == '/create-match' && !authProvider.isAuthenticated) {
      return '/login';
    }

    return null; // No redirect needed
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthWrapper()),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthLandingScreen(),
    ),
    GoRoute(
      path: '/auth-callback',
      builder: (context, state) => const AuthCallbackScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => MainLayout(child: const HomeScreen()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => MainLayout(child: const ProfileScreen()),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => MainLayout(child: const EditProfileScreen()),
    ),
    GoRoute(
      path: '/create-match',
      builder: (context, state) => MainLayout(
        child: CreateMatchScreen(
          preselectedTeam1Id: state.uri.queryParameters['team1'],
        ),
      ),
    ),
    GoRoute(
      path: '/create-team',
      builder: (context, state) => MainLayout(child: const CreateTeamScreen()),
    ),
    GoRoute(
      path: '/teams',
      builder: (context, state) => MainLayout(child: const TeamsScreen()),
    ),
    GoRoute(
      path: '/matches',
      builder: (context, state) => MainLayout(child: const MatchesScreen()),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) =>
          MainLayout(child: const AdminDashboardScreen()),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => MainLayout(child: const SettingsScreen()),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          MainLayout(child: const NotificationsScreen()),
    ),
    GoRoute(
      path: '/match/:id',
      builder: (context, state) {
        final matchId = state.pathParameters['id'];
        if (matchId == null || matchId.isEmpty) {
          // Handle invalid match ID
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });
          return MainLayout(
            child: const Scaffold(
              body: Center(child: Text('Invalid match ID')),
            ),
          );
        }
        return MainLayout(child: MatchDetailsScreen(matchId: matchId));
      },
    ),
    GoRoute(
      path: '/teams/:id',
      builder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/teams');
          });
          return MainLayout(
            child: const Scaffold(body: Center(child: Text('Invalid team ID'))),
          );
        }
        return MainLayout(child: TeamDetailsScreen(teamId: teamId));
      },
    ),
    GoRoute(
      path: '/teams/:id/manage',
      builder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/teams');
          });
          return MainLayout(
            child: const Scaffold(body: Center(child: Text('Invalid team ID'))),
          );
        }
        return MainLayout(child: TeamManagementScreen(teamId: teamId));
      },
    ),
  ],
);

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated) {
      return MainLayout(child: const HomeScreen());
    } else {
      return const AuthLandingScreen();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print build configuration for debugging
  BuildConfig.printConfig();

  // Initialize app with staging configuration
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const FootConnectApp(),
    ),
  );
}

class FootConnectApp extends StatelessWidget {
  const FootConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: BuildConfig.appName,
      debugShowCheckedModeBanner: BuildConfig.isStaging,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: context.watch<ThemeProvider>().themeMode,
      routerConfig: router,
    );
  }
}
