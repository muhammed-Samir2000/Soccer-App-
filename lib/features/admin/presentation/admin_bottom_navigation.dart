import 'package:flutter/material.dart';

import '../../../app/router.dart';

/// The manager's primary destinations stay reachable while content scrolls.
class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    onDestinationSelected: (int index) {
      if (index == selectedIndex) {
        return;
      }
      final String destination = switch (index) {
        0 => AppRouter.adminBookingsRoute,
        1 => AppRouter.adminBookingListRoute,
        2 => AppRouter.adminFinancialAnalyticsRoute,
        _ => AppRouter.adminSettingsRoute,
      };
      Navigator.of(context).pushReplacementNamed(destination);
    },
    destinations: const <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'لوحة التحكم',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'الحجوزات',
      ),
      NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights),
        label: 'المالية',
      ),
      NavigationDestination(
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune),
        label: 'الإعدادات',
      ),
    ],
  );
}
