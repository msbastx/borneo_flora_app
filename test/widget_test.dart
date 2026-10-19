import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart';

void main() {
  testWidgets('aplikasi dapat dibangun', (WidgetTester tester) async {
    await tester.pumpWidget(const BiodiversitasBorneoApp(seenGuide: true));
    await tester.pump();
    expect(find.text('FLORA IDENTIFICATION'), findsOneWidget);
  });
}
