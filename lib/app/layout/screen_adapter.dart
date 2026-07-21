import 'package:flutter/widgets.dart';

abstract final class ScreenAdapter {
  static const double designWidth = 375;
  static const double designHeight = 812;

  static double? _scale;

  static bool get isInitialized => _scale != null;

  static void init(BuildContext context) {
    initForSize(MediaQuery.sizeOf(context));
  }

  static void initForSize(Size size) {
    _scale = size.width / designWidth;
  }

  static double width(num designValue) => designValue * _requireScale();

  static double height(num designValue) => designValue * _requireScale();

  static double font(num designValue) => width(designValue);

  static void resetForTest() {
    _scale = null;
  }

  static double _requireScale() {
    if (_scale == null) {
      throw StateError('ScreenAdapter must be initialized before use.');
    }
    return _scale!;
  }
}
