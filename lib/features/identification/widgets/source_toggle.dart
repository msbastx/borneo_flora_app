import 'package:flutter/material.dart';

import '../identification_theme.dart';
import '../models/identification_source.dart';

/// Pilihan KAMERA / GALERI berbentuk kapsul.
class SourceToggle extends StatelessWidget {
  const SourceToggle({
    super.key,
    required this.source,
    required this.onChanged,
  });

  final IdentificationSource source;
  final ValueChanged<IdentificationSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: IdentColors.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'KAMERA',
            selected: source == IdentificationSource.camera,
            onTap: () => onChanged(IdentificationSource.camera),
          ),
          _Segment(
            label: 'GALERI',
            selected: source == IdentificationSource.gallery,
            onTap: () => onChanged(IdentificationSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? IdentColors.lime : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: IdentText.label(
                color: selected ? IdentColors.onLime : IdentColors.bodyOnDark,
                size: 11,
                weight: FontWeight.w700,
                spacing: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
