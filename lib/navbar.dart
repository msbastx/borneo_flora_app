import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Navbar extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTap;

  const Navbar({
    super.key,
    required this.activeIndex,
    required this.onTap,
});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color (0xFF142419),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, 'HOME'),
          _buildNavItem(1, Icons.center_focus_weak, 'IDENT'),
          _buildNavItem(2, Icons.menu_book_outlined, 'INDEX'),
          _buildNavItem(3, Icons.map_outlined, 'MAP'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = index == activeIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE2F84F) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : const Color(0xFF6B8B74),
              size: isActive ? 28 : 26
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive ? Colors.black : const Color(0xFF6B8B74),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
