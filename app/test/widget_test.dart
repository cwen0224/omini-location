import 'package:flutter_test/flutter_test.dart';

import 'package:human_rights_museum_app/app/app.dart';

void main() {
  testWidgets('app renders home title', (tester) async {
    await tester.pumpWidget(const HumanRightsMuseumApp());
    await tester.pumpAndSettle();

    expect(find.text('人權博物館APP'), findsOneWidget);
  });
}
