/// Hasil penguraian nama ilmiah, baik dari label model maupun dari katalog.
///
/// Contoh label model: "Eusideroxylon zwageri Teijsm. & Binn",
/// "Durio dulcis Bombacaceae" (famili ikut tertulis), "Dillenia sp".
class ScientificName {
  const ScientificName({
    required this.genus,
    required this.epithet,
    this.family,
    this.author,
  });

  factory ScientificName.parse(String raw) {
    final List<String> tokens =
        raw.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return const ScientificName(genus: '', epithet: '');

    String? family;
    final List<String> rest = [];
    for (final String token in tokens.skip(2)) {
      if (token.toLowerCase().endsWith('aceae')) {
        family = _capitalize(token);
      } else {
        rest.add(token);
      }
    }

    return ScientificName(
      genus: _capitalize(tokens[0]),
      epithet: tokens.length > 1 ? tokens[1].toLowerCase() : '',
      family: family,
      author: rest.isEmpty ? null : rest.join(' '),
    );
  }

  final String genus;

  /// Epitet spesies dalam huruf kecil. Kosong bila hanya ada genus.
  final String epithet;

  final String? family;

  /// Nama pemerian (otoritas), contoh "Teijsm. & Binn".
  final String? author;

  /// Bentuk tampilan baku: "Genus epitet", atau "Genus sp." bila belum
  /// teridentifikasi sampai spesies.
  String get binomial {
    if (epithet.isEmpty) return genus;
    if (epithet == 'sp') return '$genus sp.';
    return '$genus $epithet';
  }

  /// Kunci pencocokan antara label model dan data katalog.
  String get key => '${genus.toLowerCase()} ${epithet.toLowerCase()}'.trim();

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
