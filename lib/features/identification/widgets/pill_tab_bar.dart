import 'package:flutter/material.dart';

import '../identification_theme.dart';

/// Tab berbentuk kapsul. Dipakai untuk tab informasi spesies dan filter riwayat.
class PillTabBar<T> extends StatelessWidget {
  const PillTabBar({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: IdentColors.tabTrack,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final T value in values)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                label: labelOf(value),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected
                          ? IdentColors.background
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      labelOf(value),
                      style: IdentText.label(
                        color: value == selected
                            ? IdentColors.lime
                            : const Color(0xFF5A5F55),
                        size: 10,
                        weight: FontWeight.w700,
                        spacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
