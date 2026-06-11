// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroma_aid/main.dart';

void main() {
  testWidgets('ChromaAid App Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // MyApp() diganti menjadi ChromaAidApp() menyesuaikan main.dart
    await tester.pumpWidget(const ChromaAidApp());

    // Memastikan aplikasi berhasil di-render (MaterialApp terpanggil)
    // Karena aplikasi sudah masuk ke OnboardingScreen, kita tidak lagi
    // mengecek angka '0' atau ikon 'Icons.add'.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}