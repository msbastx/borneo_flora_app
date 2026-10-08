/// Format angka gaya Indonesia: koma sebagai pemisah desimal (82,3).
String formatDecimalId(double value, {int digits = 1}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');
