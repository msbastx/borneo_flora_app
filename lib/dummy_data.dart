class FloraItem {
  final String index;
  final String commonName;
  final String scientificName;

  const FloraItem({
    required this.index,
    required this.commonName,
    required this.scientificName,
  });
}

const List<FloraItem> dummyFloraList = [
  FloraItem(
    index: '01',
    commonName: 'Anggrek Hitam',
    scientificName: 'Coelogyne Pandurata',
  ),
  FloraItem(
    index: '02',
    commonName: 'Kayu Ulin',
    scientificName: 'Eusideroxylon Zwageri',
  ),
  FloraItem(
      index: '03',
      commonName: 'Ramin',
      scientificName: 'Gonystylus Bancanus',
  ),
  FloraItem(
    index: '04',
    commonName: 'Meranti Merah',
    scientificName: 'Shorea Leprosula',
  ),
];