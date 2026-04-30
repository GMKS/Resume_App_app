import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../home/screens/home_screen.dart';
import '../resume/screens/resumes_tab_screen.dart';
import '../career_tools/screens/career_tools_tab_screen.dart';
import '../portfolio/screens/portfolio_tab_screen.dart';
import '../profile/screens/profile_tab_screen.dart';
import '../../core/providers/navigation_providers.dart';

class MainDashboard extends ConsumerWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    final List<Widget> tabs = [
      const HomeScreen(),
      const ResumesTabScreen(),
      const CareerToolsTabScreen(),
      const PortfolioTabScreen(),
      const ProfileTabScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Iconsax.home),
              activeIcon: Icon(Iconsax.home_15),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.document_text),
              activeIcon: Icon(Iconsax.document_text_15),
              label: 'Resumes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.briefcase),
              activeIcon: Icon(Iconsax.briefcase5),
              label: 'Career Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.folder_2),
              activeIcon: Icon(Iconsax.folder_25),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Iconsax.user),
              activeIcon: Icon(Iconsax.user5),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
