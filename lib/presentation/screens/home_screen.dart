import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrix/presentation/providers/meter_provider.dart';
import 'package:metrix/presentation/providers/reading_provider.dart';
import 'package:metrix/presentation/screens/meter_screen.dart';
import 'package:metrix/presentation/screens/profile_screen.dart';
import 'package:metrix/presentation/screens/reading_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MetersScreen(),
    const ReadingsScreen(),
    const ProfilePage(),
  ];

  // Widget helper pour créer une icône avec badge
  Widget _buildIconWithBadge({
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    int? badgeCount,
  }) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Icon(isSelected ? selectedIcon : icon),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final pendingReadingsCount = pendingCount.asData?.value ?? 0;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            ref.invalidate(allMetersCacheFirstProvider);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Счётчики',
          ),
          NavigationDestination(
            icon: _buildIconWithBadge(
              icon: Icons.article_outlined,
              selectedIcon: Icons.article,
              isSelected: _selectedIndex == 1,
              badgeCount: pendingReadingsCount,
            ),
            label: 'Показания',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
