import 'models/flora_item.dart';

/// Data sementara. Nanti diganti sumber sebenarnya (API atau basis data lokal)
/// tanpa mengubah layar, cukup lewat FloraRepository.
///
/// Teks Anggrek Hitam diambil dari desain Figma. Teks tiga spesies lain
/// masih draf, mohon diverifikasi dengan referensi sebelum dipakai.
const List<FloraItem> dummyFloraList = [
  FloraItem(
    index: '01',
    commonName: 'Anggrek Hitam',
    scientificName: 'Coelogyne pandurata',
    englishName: 'Black orchid',
    localNames: ['Anggrek hitam', 'Kersik luway', 'Black orchid'],
    family: 'Orchidaceae',
    description: [
      'Anggrek hitam adalah maskot flora Kalimantan Timur. Namanya berasal '
          'dari bercak hitam pekat pada lidah bunga (labellum), kontras dengan '
          'kelopak hijau muda. Bunganya mekar serentak dalam satu rumpun dan '
          'berbau harum lembut menjelang siang.',
      'Tumbuh menempel pada pohon tua di hutan rawa dan tepi sungai. '
          'Populasinya menurun tajam akibat alih fungsi lahan dan pengambilan '
          'liar untuk perdagangan tanaman hias.',
    ],
    floweringSeason: 'Mar – Jun',
    altitude: '0 – 500 m',
  ),
  FloraItem(
    index: '02',
    commonName: 'Kayu Ulin',
    scientificName: 'Eusideroxylon zwageri',
    englishName: 'Bornean ironwood',
    localNames: ['Kayu ulin', 'Ulin'],
    family: 'Lauraceae',
    description: [
      'Ulin dikenal sebagai kayu besi Kalimantan. Kayunya sangat keras dan '
          'awet, tahan air serta serangan rayap, sehingga lazim dipakai untuk '
          'tiang rumah, jembatan, dan dermaga.',
    ],
  ),
  FloraItem(
    index: '03',
    commonName: 'Ramin',
    scientificName: 'Gonystylus bancanus',
    localNames: ['Ramin'],
    family: 'Thymelaeaceae',
    description: [
      'Ramin tumbuh di hutan rawa gambut Kalimantan dan Sumatra. Kayunya '
          'berwarna pucat dengan serat halus, banyak dicari untuk mebel dan '
          'bingkai, sehingga perdagangannya diatur secara internasional.',
    ],
  ),
  FloraItem(
    index: '04',
    commonName: 'Meranti Merah',
    scientificName: 'Shorea leprosula',
    localNames: ['Meranti merah'],
    family: 'Dipterocarpaceae',
    description: [
      'Meranti merah adalah pohon hutan dataran rendah dari suku '
          'Dipterocarpaceae yang tumbuh relatif cepat. Kayunya dipakai untuk '
          'konstruksi ringan, kayu lapis, dan mebel.',
    ],
  ),
];
