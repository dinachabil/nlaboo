import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/create_match_screen.dart';
import 'screens/create_team_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/match_details_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/team_management_screen.dart';
import 'screens/auth_callback_screen.dart';

final GoRouter router = GoRouter(
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Public routes that don't require authentication
    final publicRoutes = ['/login', '/signup', '/auth-callback'];

    // Get the current location (handle potential null)
    final currentLocation = state.matchedLocation ?? state.uri.path;

    // If user is not authenticated and trying to access protected route
    if (!authProvider.isAuthenticated && !publicRoutes.contains(currentLocation)) {
      return '/login';
    }

    // If user is authenticated and trying to access login/signup, redirect to home
    if (authProvider.isAuthenticated && publicRoutes.contains(currentLocation)) {
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
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/create-match',
      builder: (context, state) => const CreateMatchScreen(),
    ),
    GoRoute(
      path: '/create-team',
      builder: (context, state) => const CreateTeamScreen(),
    ),
    GoRoute(
      path: '/teams',
      builder: (context, state) => const TeamsScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
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
          return const Scaffold(
            body: Center(
              child: Text('Invalid match ID'),
            ),
          );
        }
        return MatchDetailsScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/auth-callback',
      builder: (context, state) => const AuthCallbackScreen(),
    ),
    GoRoute(
      path: '/teams/:id',
      builder: (context, state) {
        final teamId = state.pathParameters['id'];
        if (teamId == null || teamId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/teams');
          });
          return const Scaffold(
            body: Center(
              child: Text('Invalid team ID'),
            ),
          );
        }
        // TODO: Create TeamDetailsScreen
        return Scaffold(
          appBar: AppBar(title: const Text('Team Details')),
          body: const Center(
            child: Text('Team Details Screen - Coming Soon'),
          ),
        );
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
          return const Scaffold(
            body: Center(
              child: Text('Invalid team ID'),
            ),
          );
        }
        return TeamManagementScreen(teamId: teamId);
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}