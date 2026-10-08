import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Data satu tujuan pada navigasi bawah.
class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const List<NavDestination> kNavDestinations = [
  NavDestination(icon: Icons.home_filled, label: 'HOME'),
  NavDestination(icon: Icons.center_focus_weak, label: 'IDENT'),
  NavDestination(icon: Icons.menu_book_outlined, label: 'INDEKS'),
  NavDestination(icon: Icons.map_outlined, label: 'PETA'),
];

/// Navigasi bawah. Tidak menyimpan state, indeks aktif diatur oleh pemanggil.
class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.destinations = kNavDestinations,
    this.backgroundColor = AppColors.navBackground,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> destinations;

  /// Warna kapsul navbar. Layar bergaya gelap bisa memakai warna lebih terang
  /// agar kapsul tetap terlihat.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
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
    final Color color = isActive ? Colors.black : AppColors.sage;

    return Semantics(
      button: true,
      selected: isActive,
      label: destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.neonLime : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, color: color, size: isActive ? 28 : 26),
              const SizedBox(height: 4),
              Text(
                destination.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
