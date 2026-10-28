import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart';

void main() {
  testWidgets('layar panduan awal dapat dibangun', (WidgetTester tester) async {
    await tester.pumpWidget(const FloraApp(seenGuide: false));
    await tester.pump();

    expect(find.text('Kenali flora Kalimantan dari satu foto'), findsOneWidget);
  });
}