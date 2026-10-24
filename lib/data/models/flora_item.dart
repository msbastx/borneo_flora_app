import '../../core/utils/scientific_name.dart';

/// Satu spesies flora di katalog. Hanya tiga bidang pertama yang wajib,
/// sisanya boleh kosong dan dilengkapi bertahap.
class FloraItem {
  const FloraItem({
    this.serverId,
    required this.index,
    required this.commonName,
    required this.scientificName,
    this.englishName,
    this.localNames = const [],
    this.family,
    this.description = const [],
    this.floweringSeason,
    this.altitude,
    this.conservationStatus,
    this.conservationNote,
    this.isVerified = true,
  });

  /// ID spesies pada PostgreSQL/Django, null untuk katalog lokal/dummy.
  final int? serverId;

  /// False untuk entri placeholder development yang belum diverifikasi.
  final bool isVerified;

  final String index;
  final String commonName;
  final String scientificName;
  final String? englishName;

  /// Nama daerah, termasuk nama umum lain.
  final List<String> localNames;

  final String? family;

  /// Penjelasan umum, satu elemen per paragraf.
  final List<String> description;

  /// Contoh: "Mar – Jun".
  final String? floweringSeason;

  /// Contoh: "0 – 500 m".
  final String? altitude;

  /// Contoh: "Rentan (VU)".
  final String? conservationStatus;
  final String? conservationNote;

  ScientificName get parsedName => ScientificName.parse(scientificName);
}
