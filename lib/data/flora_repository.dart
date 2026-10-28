import 'dart:convert';
import 'package:flutter/services.dart';

import '../core/constants/app_assets.dart';
import '../core/utils/scientific_name.dart';
import 'dummy_data.dart';
import 'models/flora_item.dart';

class FloraRepository {
  FloraRepository({List<FloraItem>? items}) {
    final initial = items ?? _cachedStaticItems ?? dummyFloraList;
    _setItems(initial);
  }

  static List<FloraItem>? _cachedStaticItems;

  List<FloraItem> _items = const [];
  Map<String, FloraItem> _byKey = const {};

  List<FloraItem> get all => _items;

  void _setItems(List<FloraItem> items) {
    _items = items;
    _byKey = {for (final FloraItem i in items) i.parsedName.key: i};
  }

  /// Memuat seluruh 75 spesies dari assets/species_labels.json & class_names.txt
  /// agar katalog offline menampilkan 75 spesies lengkap tanpa membengkakkan ukuran app.
  Future<void> ensureLoadedFromAssets() async {
    if (_cachedStaticItems != null && _cachedStaticItems!.length > dummyFloraList.length) {
      _setItems(_cachedStaticItems!);
      return;
    }

    try {
      final Map<String, FloraItem> dummyByKey = {
        for (final item in dummyFloraList) item.parsedName.key: item,
      };

      final List<FloraItem> loaded = [];

      // Coba muat dari assets/species_labels.json terlebih dahulu
      try {
        final String jsonRaw = await rootBundle.loadString('assets/species_labels.json');
        final dynamic decoded = json.decode(jsonRaw);
        if (decoded is List) {
          for (int i = 0; i < decoded.length; i++) {
            final entry = decoded[i];
            if (entry is Map) {
              final sciName = (entry['scientific_name'] ?? entry['label'] ?? '').toString().trim();
              if (sciName.isEmpty) continue;
              final parsedKey = ScientificName.parse(sciName).key;
              final dummy = dummyByKey[parsedKey];

              final typeStr = (entry['type'] ?? entry['species_type'] ?? '').toString().toLowerCase();
              final isEndemic = entry['is_endemic'] == true ||
                  typeStr.contains('endemic') ||
                  typeStr.contains('endemik') ||
                  (dummy?.conservationNote?.toLowerCase().contains('endemik') ?? false);

              loaded.add(
                FloraItem(
                  serverId: entry['id'] is num ? (entry['id'] as num).toInt() : dummy?.serverId,
                  index: (i + 1).toString().padLeft(2, '0'),
                  commonName: (entry['common_name'] ?? dummy?.commonName ?? sciName).toString(),
                  scientificName: sciName,
                  family: (entry['family'] ?? dummy?.family)?.toString(),
                  localNames: dummy?.localNames ?? const [],
                  description: dummy?.description ?? const [],
                  conservationStatus: (entry['iucn_label'] ?? dummy?.conservationStatus)?.toString(),
                  conservationNote: (entry['notes'] ?? dummy?.conservationNote)?.toString(),
                  iucnCode: (entry['iucn'] ?? dummy?.iucnCode ?? 'NE').toString(),
                  isEndemic: isEndemic,
                  isProtected: (entry['p106'] ?? '').toString().toLowerCase().contains('dilindungi') ||
                      (dummy?.isProtected ?? false),
                ),
              );
            }
          }
        }
      } catch (_) {
        // Jika format species_labels.json berbeda, fallback ke class_names.txt (75 spesies)
      }

      if (loaded.isEmpty) {
        final String rawClasses = await rootBundle.loadString(AppAssets.classNames);
        final List<String> lines = rawClasses
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        for (int i = 0; i < lines.length; i++) {
          final String sciName = lines[i];
          final String key = ScientificName.parse(sciName).key;
          final FloraItem? dummy = dummyByKey[key];

          loaded.add(
            FloraItem(
              serverId: dummy?.serverId,
              index: (i + 1).toString().padLeft(2, '0'),
              commonName: dummy?.commonName ?? sciName,
              scientificName: sciName,
              family: dummy?.family,
              localNames: dummy?.localNames ?? const [],
              description: dummy?.description ?? const [],
              conservationStatus: dummy?.conservationStatus,
              conservationNote: dummy?.conservationNote,
              iucnCode: dummy?.iucnCode ?? 'NE',
              isEndemic: dummy?.isEndemic ??
                  sciName.toLowerCase().contains('balikpapanensis') ||
                      sciName.toLowerCase().contains('borneensis'),
              isProtected: dummy?.isProtected ?? false,
            ),
          );
        }
      }

      if (loaded.isNotEmpty) {
        _cachedStaticItems = loaded;
        _setItems(loaded);
      }
    } catch (_) {}
  }

  FloraItem? findByScientificName(String name) =>
      _byKey[ScientificName.parse(name).key];
}