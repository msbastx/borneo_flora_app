import '../../core/utils/scientific_name.dart';

/// Satu spesies flora di katalog.
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
    this.iucnCode = 'NE',
    this.isEndemic = false,
    this.endemicStatusKnown = false,
    this.isProtected = false,
    this.imageUrl,
    this.isVerified = false,
  });

  /// ID spesies pada PostgreSQL/Django, null untuk katalog lokal/dummy.
  final int? serverId;

  /// False untuk entri placeholder development yang belum diverifikasi.
  final bool isVerified;

  final String index;
  final String commonName;
  final String scientificName;
  final String? englishName;
  final List<String> localNames;
  final String? family;
  final List<String> description;
  final String? floweringSeason;
  final String? altitude;
  final String? conservationStatus;
  final String? conservationNote;

  /// Tambahan atribut untuk logika verifikasi Endemik & Pelaporan
  final String iucnCode;
  final bool isEndemic;

  /// True hanya bila metadata terverifikasi menyatakan Endemic/Native/Invasive.
  /// False berarti status tidak diketahui, bukan otomatis non-endemik.
  final bool endemicStatusKnown;

  final bool isProtected;
  final String? imageUrl;

  ScientificName get parsedName => ScientificName.parse(scientificName);
}