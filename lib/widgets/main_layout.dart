import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/localization_service.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Bottom navigation items
  static const List<String> _navLabels = [
    'home',
    'teams',
    'matches',
    'notifications',
    'profile',
  ];
  static const List<IconData> _navIcons = [
    Icons.home,
    Icons.groups,
    Icons.sports_soccer,
    Icons.notifications,
    Icons.person,
  ];
  static const List<String> _navRoutes = [
    '/home',
    '/teams',
    '/matches',
    '/notifications',
    '/profile',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update selected index based on current route
    final location = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
    final index = _navRoutes.indexWhere((route) => location.startsWith(route));
    if (index != -1 && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        title: Text(
          'FootConnect',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => context.go('/settings'),
            tooltip: LocalizationService().translate('settings'),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: List.generate(
          _navLabels.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_navIcons[index]),
            label: LocalizationService().translate(
              _navLabels[index].toLowerCase(),
            ),
          ),
        ),
      ),
    );
  }
}
