import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    _items = List<FloraItem>.unmodifiable(items);
    _byKey = {for (final FloraItem item in items) item.parsedName.key: item};
  }

  /// Memuat daftar 75 kelas model sebagai katalog offline ringan.
  /// Label kelas bukan metadata botani: nama umum, famili, endemisme, dan IUCN
  /// tidak dianggap valid kecuali sumber menyertakan is_verified=true.
  Future<void> ensureLoadedFromAssets() async {
    final cached = _cachedStaticItems;
    if (cached != null && cached.length > dummyFloraList.length) {
      _setItems(cached);
      return;
    }

    final Map<String, FloraItem> dummyByKey = {
      for (final FloraItem item in dummyFloraList) item.parsedName.key: item,
    };
    final List<FloraItem> loaded = [];

    try {
      final String raw = await rootBundle.loadString('assets/species_labels.json');
      final dynamic decoded = json.decode(raw);
      if (decoded is List) {
        for (int i = 0; i < decoded.length; i++) {
          final dynamic row = decoded[i];
          if (row is! Map) continue;
          final entry = Map<String, dynamic>.from(row);
          final String label = (entry['model_label'] ??
                  entry['scientific_name'] ?? entry['label'] ?? '')
              .toString().trim();
          if (label.isEmpty) continue;

          final String nameKey = ScientificName.parse(label).key;
          final FloraItem? dummy = dummyByKey[nameKey];
          final bool verified = entry['is_verified'] == true;
          final String type = (entry['species_type'] ?? entry['type'] ?? '')
              .toString().trim().toLowerCase();
          final bool typeKnown = verified &&
              const {'endemic', 'endemik', 'native', 'invasive'}.contains(type);
          final bool endemic = typeKnown &&
              (type == 'endemic' || type == 'endemik');

          final String? suppliedCommon = _valid(entry['common_name']);
          final String commonName = verified && suppliedCommon != null
              ? suppliedCommon
              : ScientificName.parse(label).binomial;
          final String scientificName = verified
              ? (_valid(entry['scientific_name']) ?? ScientificName.parse(label).binomial)
              : ScientificName.parse(label).binomial;

          loaded.add(FloraItem(
            serverId: verified && entry['id'] is num
                ? (entry['id'] as num).toInt()
                : null,
            index: (i + 1).toString().padLeft(2, '0'),
            commonName: commonName,
            scientificName: scientificName,
            family: verified ? _valid(entry['family_name'] ?? entry['family']) : null,
            localNames: verified ? (dummy?.localNames ?? const []) : const [],
            description: verified
                ? _description(entry['description'] ?? entry['short_summary'])
                : const [],
            conservationStatus: verified ? _valid(entry['iucn_label']) : null,
            conservationNote: verified ? _valid(entry['notes']) : null,
            iucnCode: verified ? (_valid(entry['iucn']) ?? 'NE') : 'NE',
            isEndemic: endemic,
            endemicStatusKnown: typeKnown,
            isProtected: verified &&
                (entry['p106']?.toString().toLowerCase().contains('dilindungi') ?? false),
            isVerified: verified,
          ));
        }
      }
    } catch (e) {
      debugPrint('[FloraRepository] Gagal membaca species_labels.json: $e');
    }

    // Fallback tetap menampilkan semua kelas, tetapi tidak menandai metadata valid.
    if (loaded.isEmpty) {
      try {
        final String raw = await rootBundle.loadString(AppAssets.classNames);
        final List<String> labels = raw
            .split('\n')
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toList();
        for (int i = 0; i < labels.length; i++) {
          final name = ScientificName.parse(labels[i]).binomial;
          loaded.add(FloraItem(
            index: (i + 1).toString().padLeft(2, '0'),
            commonName: name,
            scientificName: name,
            isVerified: false,
            endemicStatusKnown: false,
          ));
        }
      } catch (e) {
        debugPrint('[FloraRepository] Gagal membaca class_names.txt: $e');
      }
    }

    if (loaded.isNotEmpty) {
      _cachedStaticItems = List<FloraItem>.unmodifiable(loaded);
      _setItems(_cachedStaticItems!);
    }
  }

  FloraItem? findByScientificName(String name) =>
      _byKey[ScientificName.parse(name).key];

  static String? _valid(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty || text == '-' || text.toLowerCase() == 'unknown' ||
        text.toLowerCase().startsWith('nama umum belum') ||
        text.toLowerCase().startsWith('[dev]')) return null;
    return text;
  }

  static List<String> _description(Object? value) {
    if (value is! String || value.trim().isEmpty) return const [];
    return value.split(RegExp(r'\n\s*\n'))
        .map((String paragraph) => paragraph.trim())
        .where((String paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
  }
}
