import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(icon: Icons.home_rounded, label: 'HOME'),
  NavDestination(icon: Icons.center_focus_weak_rounded, label: 'IDENTIFIKASI'),
  NavDestination(icon: Icons.menu_book_outlined, label: 'INDEKS'),
  NavDestination(icon: Icons.map_outlined, label: 'PETA'),
];

class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.destinations = kNavDestinations,
    this.backgroundColor = AppColors.base100,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> destinations;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.base300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < destinations.length; i++)
              _NavItem(
                destination: destinations[i],
                isActive: i == activeIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg =
        isActive ? AppColors.primaryContent : AppColors.mutedGrey;

    return Semantics(
      button: true,
      selected: isActive,
      label: destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, color: fg, size: 22),
              const SizedBox(height: 2),
              Text(
                destination.label,
                style: AppText.monoLabel.copyWith(
                  fontSize: 9,
                  color: fg,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
