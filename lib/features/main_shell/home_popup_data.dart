import '../../core/json/json.dart';

enum HomePopupType {
  none,
  appUpgrade,
  membershipUpgrade,
  marketing,
  unsupported,
}

class HomePopupData {
  const HomePopupData({
    required this.type,
    this.version = '',
    this.message = '',
    this.imageUrl = '',
    this.targetUrl = '',
  });

  final HomePopupType type;
  final String version;
  final String message;
  final String imageUrl;
  final String targetUrl;

  bool get shouldShow => switch (type) {
    HomePopupType.appUpgrade => true,
    HomePopupType.marketing => imageUrl.isNotEmpty,
    _ => false,
  };

  String get displayVersion {
    final value = version.trim();
    if (value.isEmpty) return '';
    return value.toUpperCase().startsWith('V') ? value : 'V$value';
  }

  factory HomePopupData.fromResponse(Json states) {
    final dialog = states['rheologists'];
    return HomePopupData(
      type: _type(states['sociologeses'].intValue),
      version: dialog['penes'].stringValue.trim(),
      message: dialog['pinchbug'].stringValue.trim(),
      imageUrl: dialog['cilantro'].stringValue.trim(),
      targetUrl: dialog['millipede'].stringValue.trim(),
    );
  }

  static HomePopupType _type(int value) => switch (value) {
    0 => HomePopupType.none,
    1 => HomePopupType.appUpgrade,
    2 => HomePopupType.membershipUpgrade,
    3 => HomePopupType.marketing,
    _ => HomePopupType.unsupported,
  };
}
