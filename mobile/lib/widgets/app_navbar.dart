import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';

class AppNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? darkBorder : lightBorder;
    final surfaceColor = isDark ? darkSurface : lightSurface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(
            color: borderColor,
            width: 0.5,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(context, 0, Icons.home_rounded,
                    Icons.home_outlined, 'Beranda'),
                _navItem(context, 1, Icons.bar_chart_rounded,
                    Icons.bar_chart_outlined, 'Progress'),
                _navItem(context, 2, Icons.restaurant_menu_rounded,
                    Icons.restaurant_menu_outlined, 'Diet'),
                _navItem(context, 3, Icons.fitness_center_rounded,
                    Icons.fitness_center_outlined, 'Workout'),
                _navItem(context, 4, Icons.settings_rounded,
                    Icons.settings_outlined, 'Setting'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData activeIcon,
      IconData inactiveIcon, String label) {
    final bool isActive = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? darkTextSecondary : lightTextSecondary;
    final activeTextColor = isDark ? darkTextPrimary : lightTextPrimary;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              ShaderMask(
                shaderCallback: (bounds) => buttonGradient.createShader(bounds),
                child: Icon(
                  activeIcon,
                  color: Colors.white,
                  size: 24,
                ),
              )
            else
              Icon(
                inactiveIcon,
                color: inactiveColor,
                size: 24,
              ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeTextColor : inactiveColor,
                letterSpacing: -0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}