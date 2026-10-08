import '../../../core/utils/scientific_name.dart';
import '../../../data/models/flora_item.dart';
import 'flora_prediction.dart';

/// Satu prediksi model yang sudah dipasangkan dengan data katalog (bila ada).
/// Layar hanya membaca kelas ini, tidak perlu tahu asal datanya.
class IdentifiedFlora {
  IdentifiedFlora({required this.prediction, this.item})
      : name = ScientificName.parse(prediction.label);

  final FloraPrediction prediction;

  /// Null bila spesies ini belum ada di katalog.
  final FloraItem? item;

  /// Hasil penguraian label model.
  final ScientificName name;

  bool get hasCatalogEntry => item != null;

  /// Nama umum dari katalog, atau nama ilmiah bila belum ada di katalog.
  String get title => item?.commonName ?? name.binomial;

  String get scientificName => item?.parsedName.binomial ?? name.binomial;

  /// Nama ilmiah hanya jadi subjudul bila judulnya nama umum.
  bool get showsScientificName => hasCatalogEntry;

  String? get family => item?.family ?? name.family;

  /// Baris kecil di bawah nama, contoh "BLACK ORCHID · KERSIK LUWAY".
  String? get caption {
    final FloraItem? item = this.item;
    if (item == null) return null;

    final Set<String> seen = {item.commonName.toLowerCase()};
    final List<String> parts = [];
    void add(String? value) {
      if (value == null || value.trim().isEmpty) return;
      if (seen.add(value.toLowerCase())) parts.add(value.toUpperCase());
    }

    add(item.englishName);
    for (final String local in item.localNames) {
      add(local);
      if (parts.length >= 2) break;
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
