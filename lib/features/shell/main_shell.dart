import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final onHome = navigationShell.currentIndex == 0;

    // 横屏首页按车载全屏布局，隐藏底部导航腾出高度
    final hideBottomBar = isLandscape && onHome;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: hideBottomBar
          ? null
          : NavigationBar(
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primary.withValues(alpha: 0.2),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emoji_emotions_outlined),
                  selectedIcon: Icon(Icons.emoji_emotions),
                  label: '表情',
                ),
                NavigationDestination(
                  icon: Icon(Icons.brush_outlined),
                  selectedIcon: Icon(Icons.brush),
                  label: 'DIY',
                ),
                NavigationDestination(
                  icon: Icon(Icons.subtitles_outlined),
                  selectedIcon: Icon(Icons.subtitles),
                  label: '弹幕',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '我的',
                ),
              ],
            ),
    );
  }
}
