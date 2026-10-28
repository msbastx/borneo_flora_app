import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../features/report/report_config.dart';
import 'models/flora_item.dart';

class SpeciesApiRepository {
  SpeciesApiRepository({Dio? dio, ApiClient? client})
      : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: '${ReportConfig.apiBaseUrl}/',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

  final Dio _dio;
  final Map<int, FloraItem> _cache = {};
  final Map<int, Future<FloraItem>> _pending = {};

  Future<FloraItem> findByAiKey(int aiKey) {
    final FloraItem? cached = _cache[aiKey];
    if (cached != null) return Future<FloraItem>.value(cached);

    final Future<FloraItem>? pending = _pending[aiKey];
    if (pending != null) return pending;

    final Future<FloraItem> request = _fetchByAiKey(aiKey).whenComplete(() {
      _pending.remove(aiKey);
    });
    _pending[aiKey] = request;
    return request;
  }

  Future<FloraItem> _fetchByAiKey(int aiKey) async {
    if (aiKey < 0) {
      throw ArgumentError.value(aiKey, 'aiKey', 'Indeks kelas tidak boleh negatif.');
    }

    final Response<Object?> response = await _dio.get<Object?>(
      'species/lookup/',
      queryParameters: {'ai_key': aiKey},
    );

    final Object? data = response.data;
    if (data is! Map) {
      throw const FormatException('Respons lookup spesies bukan objek JSON.');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(data);
    final Object? returnedKey = json['ai_key'];
    if (returnedKey is! num || returnedKey.toInt() != aiKey) {
      throw FormatException(
        'ai_key respons tidak cocok. Diminta $aiKey, diterima $returnedKey.',
      );
    }

    final FloraItem item = _toFloraItem(json, requestedAiKey: aiKey);
    _cache[aiKey] = item;
    return item;
  }

  FloraItem _toFloraItem(
      Map<String, dynamic> json, {
        required int requestedAiKey,
      }) {
    final bool isVerified = json['is_verified'] == true;
    final int? serverId = _asInt(json['id']);
    final String scientificName = _nonEmptyString(json['scientific_name']) ??
        'Kelas model $requestedAiKey';
    final String? rawCommonName = _nonEmptyString(json['common_name']);
    final Map<String, dynamic> taxonomy = _asStringMap(json['taxonomy']);

    final bool commonNameIsPlaceholder = rawCommonName == null ||
        rawCommonName.toLowerCase().startsWith('nama umum belum tersedia');
    final String commonName = !isVerified || commonNameIsPlaceholder
        ? scientificName
        : rawCommonName;

    final String? family = isVerified
        ? _validMetadata(_nonEmptyString(taxonomy['family']))
        : null;
    final List<String> paragraphs = isVerified
        ? _descriptionParagraphs(_nonEmptyString(json['description']))
        : const <String>[];
    final String? iucnLabel = isVerified
        ? _validMetadata(_nonEmptyString(json['iucn_label']))
        : null;
    final String? notes = isVerified
        ? _validMetadata(_nonEmptyString(json['notes']))
        : null;

    // Baca status Endemik, kode IUCN, dan perlindungan P.106 dari respons Django
    final String typeRaw = (_nonEmptyString(json['type']) ?? '').toLowerCase();
    final String typeLabel = (_nonEmptyString(json['type_label']) ?? '').toLowerCase();
    final bool isEndemic = typeRaw == 'endemic' || typeLabel.contains('endemik');

    final String iucnCode = _nonEmptyString(json['iucn']) ?? 'NE';
    final String p106Raw = (_nonEmptyString(json['p106']) ?? '').toLowerCase();
    final bool isProtected = p106Raw.contains('dilindungi');
    final String? imageUrl = _nonEmptyString(json['thumbnail_url']) ??
        _nonEmptyString(json['image_url']);

    return FloraItem(
      serverId: serverId,
      index: (requestedAiKey + 1).toString().padLeft(2, '0'),
      commonName: commonName,
      scientificName: scientificName,
      family: family,
      description: paragraphs,
      conservationStatus: iucnLabel,
      conservationNote: notes,
      iucnCode: iucnCode,
      isEndemic: isEndemic,
      isProtected: isProtected,
      imageUrl: imageUrl,
      isVerified: isVerified,
    );
  }

  static int? _asInt(Object? value) => value is num ? value.toInt() : null;

  static Map<String, dynamic> _asStringMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(value);
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    return trimmed;
  }

  static String? _validMetadata(String? value) {
    if (value == null) return null;
    final String lower = value.toLowerCase();
    if (lower == 'unknown' ||
        lower.startsWith('[dev]') ||
        lower.contains('belum diverifikasi') ||
        lower.contains('belum tersedia')) {
      return null;
    }
    return value;
  }

  static List<String> _descriptionParagraphs(String? description) {
    if (description == null) return const <String>[];
    return description
        .split(RegExp(r'\n\s*\n'))
        .map((String paragraph) => paragraph.trim())
        .where((String paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
  }
}