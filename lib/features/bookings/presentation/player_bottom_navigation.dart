import 'package:flutter/material.dart';

import '../../../app/router.dart';

class PlayerBottomNavigation extends StatelessWidget {
  const PlayerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.playerId,
  });

  final int selectedIndex;
  final String playerId;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 360;
    return NavigationBar(
      selectedIndex: selectedIndex,
      labelBehavior: compact
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (int index) {
        if (index == selectedIndex) {
          return;
        }
        final String route = switch (index) {
          0 => AppRouter.slotsRoute,
          1 => AppRouter.myBookingsRoute,
          _ => AppRouter.notificationsRoute,
        };
        Navigator.of(
          context,
        ).pushReplacementNamed(route, arguments: index == 1 ? playerId : null);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.sports_soccer_outlined),
          selectedIcon: Icon(Icons.sports_soccer),
          label: 'احجز',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'حجوزاتي',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'الإشعارات',
        ),
      ],
    );
  }
}
