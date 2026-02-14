import 'package:flutter/material.dart';
import '../pages/completed_tasks_page.dart';
import '../pages/groups_page.dart';
import '../pages/home_page.dart';
import '../pages/individual_tasks_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';

enum AppTab { tasks, individual, groups, done, search, more }

class AppBottomNav extends StatelessWidget {
  final AppTab currentTab;

  const AppBottomNav({
    super.key,
    required this.currentTab,
  });

  void _goTo(BuildContext context, AppTab tab) {
    if (tab == currentTab) return;

    late final Widget page;
    switch (tab) {
      case AppTab.tasks:
        page = const HomePage();
        break;
      case AppTab.individual:
        page = const IndividualTasksPage();
        break;
      case AppTab.groups:
        page = const GroupsPage();
        break;
      case AppTab.done:
        page = const CompletedTasksPage();
        break;
      case AppTab.search:
        page = const SearchPage();
        break;
      case AppTab.more:
        page = const SettingsPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).colorScheme.primary;

    return NavigationBar(
      selectedIndex: currentTab.index,
      backgroundColor: const Color(0xFFF3F0F8),
      indicatorColor: selectedColor.withOpacity(0.18),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) => _goTo(context, AppTab.values[index]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.check_box_outlined),
          selectedIcon: Icon(Icons.check_box_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox_rounded),
          label: 'Individual',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Groups',
        ),
        NavigationDestination(
          icon: Icon(Icons.check_circle_outline_rounded),
          selectedIcon: Icon(Icons.check_circle_rounded),
          label: 'Done',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          selectedIcon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz_rounded),
          selectedIcon: Icon(Icons.more_horiz_rounded),
          label: 'More',
        ),
      ],
    );
  }
}
