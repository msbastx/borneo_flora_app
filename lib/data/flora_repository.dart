import '../core/utils/scientific_name.dart';
import 'dummy_data.dart';
import 'models/flora_item.dart';

/// Satu pintu untuk data flora. Layar identifikasi dan katalog sama-sama
/// membaca dari sini, jadi mengganti sumber data cukup di satu tempat.
class FloraRepository {
  FloraRepository({List<FloraItem> items = dummyFloraList})
      : _items = items,
        _byKey = {for (final FloraItem i in items) i.parsedName.key: i};

  final List<FloraItem> _items;
  final Map<String, FloraItem> _byKey;

  List<FloraItem> get all => _items;

  /// Mencocokkan label model (misal "Eusideroxylon zwageri Teijsm. & Binn")
  /// dengan data katalog lewat genus dan epitet. Null bila belum ada di data.
  FloraItem? findByScientificName(String name) =>
      _byKey[ScientificName.parse(name).key];
}
