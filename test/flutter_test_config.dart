import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads custom fonts before running tests to ensure deterministic rendering.
///
/// Golden tests depend on consistent font rendering across machines.
/// Without loading the custom Oxanium font, Flutter falls back to a default
/// font that may differ between test environments, causing floating diffs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Load the Oxanium variable font used throughout the app.
  // This ensures golden test snapshots render consistently.
  await _loadFont('Oxanium', 'assets/fonts/Oxanium-VariableFont_wght.ttf');

  await testMain();
}

/// Helper to load a font family from an asset file.
///
/// [family] is the font family name (e.g., 'Oxanium').
/// [assetPath] is the path relative to the package root (e.g., 'assets/fonts/...').
Future<void> _loadFont(String family, String assetPath) async {
  final fontLoader = FontLoader(family);
  final fontData = File(assetPath).readAsBytesSync();
  fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
  await fontLoader.load();
}
