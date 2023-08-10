import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pigeon_pass_mesage_backandforth/HomePage.dart';
import 'package:pigeon_pass_mesage_backandforth/main.dart';

void main() {
  testWidgets('main started block', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that HomePage is rendered
    expect(find.byType(HomePage), findsOneWidget);
  });
}
