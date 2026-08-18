import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/navigation/presentation/providers/bottom_nav_provider.dart';
import 'package:staff_app/features/products/presentation/pages/products_list_page.dart';
import 'package:staff_app/features/settings/presentation/pages/settings_page.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);

    final pages = const [
      ProductsListPage(),
      SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          color: Colors.white,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: index,
          elevation: 0,
          selectedItemColor: const Color(0xFF1F2937),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: (value) {
            ref.read(bottomNavIndexProvider.notifier).state = value;
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.cube_box),
              activeIcon: Icon(CupertinoIcons.cube_box_fill),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.gear_alt),
              activeIcon: Icon(CupertinoIcons.gear_alt_fill),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
