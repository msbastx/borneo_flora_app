import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Species {
  final int id;
  final int aiKey;
  final String scientificName;
  final String commonName;
  final String familyName;
  final String speciesType;
  final String p106;
  final bool isSensitive;
  final String description;
  final String imageAsset;

  Species({
    required this.id,
    required this.aiKey,
    required this.scientificName,
    required this.commonName,
    required this.familyName,
    required this.speciesType,
    required this.p106,
    required this.isSensitive,
    required this.description,
    required this.imageAsset,
});

  factory Species.fromMap(Map<String, dynamic> map) {
    return Species(
      id: map['id'],
      aiKey: map['ai_key'],
      scientificName: map['scientific_name'],
      commonName: map['common_name'],
      familyName: map['family_name'],
      speciesType: map['species_type'],
      p106: map['p106'],
      isSensitive: map['is_sensitive'] == 1,
      description: map['description'],
      imageAsset: map['image_asset'],
    );
  }
}

class DatabseHelper {
  static final DatabaseHelper instace = DatabseHelper._init();
  static Databse? _database;

  DatabaseHelper._init();

  Future<Database> get databse async {
    if (_database != null) return _database!;
    _database = await _initDB('borneo_flora.db');
    return _databse!;1
  }
}