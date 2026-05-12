import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kFontFamily = 'Oxanium';
const _kFontAsset = 'assets/fonts/Oxanium-VariableFont_wght.ttf';

/// Loads custom fonts before running tests to ensure deterministic rendering.
///
/// Golden tests depend on consistent font rendering across machines.
/// Without loading the custom Oxanium font, Flutter falls back to a default
/// font that may differ between test environments, causing floating diffs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont(_kFontFamily, _kFontAsset);
  await testMain();
}

/// Helper to load a font family from an asset file.
///
/// [family] is the font family name (e.g., 'Oxanium').
/// [assetPath] is the path relative to the package root (e.g., 'assets/fonts/...').
Future<void> _loadFont(String family, String assetPath) async {
  final fontLoader = FontLoader(family);
  fontLoader.addFont(rootBundle.load(assetPath));
  await fontLoader.load();
}
