import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// HomeShell wraps the authenticated sections of the app in a bottom
/// navigation bar (Dashboard / Students / Certificates / Profile).
///
/// It is the builder for a `StatefulShellRoute.indexedStack`, so each tab
/// keeps its scroll position and search state while switching. Deeper routes
/// (details, add/edit) are registered in their branch and render inside this
/// shell, giving every authenticated screen the shared navigation bar.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.military_tech_outlined),
            selectedIcon: Icon(Icons.military_tech_rounded),
            label: 'Certificates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
