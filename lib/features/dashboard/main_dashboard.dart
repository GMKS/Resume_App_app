import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../home/screens/home_screen.dart';
import '../resume/screens/resumes_tab_screen.dart';
import '../career_tools/screens/career_tools_tab_screen.dart';
import '../portfolio/screens/portfolio_tab_screen.dart';
import '../profile/screens/profile_tab_screen.dart';
import '../../core/providers/navigation_providers.dart';

class MainDashboard extends ConsumerStatefulWidget {
  const MainDashboard({super.key});

  @override
  ConsumerState<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends ConsumerState<MainDashboard> {
  DateTime? _lastBackPressAt;

  static const double _wideLayoutBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    const tabs = <Widget>[
      HomeScreen(),
      ResumesTabScreen(),
      CareerToolsTabScreen(),
      PortfolioTabScreen(),
      ProfileTabScreen(),
    ];

    const destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Icon(Iconsax.home),
        selectedIcon: Icon(Iconsax.home_15),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(Iconsax.document_text),
        selectedIcon: Icon(Iconsax.document_text_15),
        label: Text('Resumes'),
      ),
      NavigationRailDestination(
        icon: Icon(Iconsax.briefcase),
        selectedIcon: Icon(Iconsax.briefcase5),
        label: Text('Career Tools'),
      ),
      NavigationRailDestination(
        icon: Icon(Iconsax.folder_2),
        selectedIcon: Icon(Iconsax.folder_25),
        label: Text('Portfolio'),
      ),
      NavigationRailDestination(
        icon: Icon(Iconsax.user),
        selectedIcon: Icon(Iconsax.user5),
        label: Text('Profile'),
      ),
    ];

    final content = IndexedStack(
      index: currentTab,
      children: tabs,
    );

    final dashboardScaffold = MediaQuery.sizeOf(context).width >=
            _wideLayoutBreakpoint
        ? Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).navigationRailTheme.backgroundColor,
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerTheme.color ??
                              AppColors.divider,
                        ),
                      ),
                    ),
                    child: NavigationRail(
                      selectedIndex: currentTab,
                      labelType: NavigationRailLabelType.all,
                      useIndicator: true,
                      onDestinationSelected: (index) =>
                          ref.read(currentTabProvider.notifier).state = index,
                      destinations: destinations,
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          )
        : Scaffold(
            body: content,
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
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
                  onTap: (index) =>
                      ref.read(currentTabProvider.notifier).state = index,
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
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (currentTab != 0) {
          ref.read(currentTabProvider.notifier).state = 0;
          return;
        }

        final now = DateTime.now();
        final shouldExit = _lastBackPressAt != null &&
            now.difference(_lastBackPressAt!) < const Duration(seconds: 2);
        if (shouldExit) {
          SystemNavigator.pop();
          return;
        }

        _lastBackPressAt = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit the app.'),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
      },
      child: dashboardScaffold,
    );
  }
}
