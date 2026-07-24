import 'dart:convert';

import '../network/api_crypto.dart';

class DaliLocationSnapshot {
  const DaliLocationSnapshot({
    this.province = '',
    this.locality = '',
    this.fullAddress = '',
    this.countryCode = '',
    this.country = '',
    this.street = '',
    this.latitude = '',
    this.longitude = '',
    this.city = '',
    this.permissionStatus = '',
  });

  static const empty = DaliLocationSnapshot();

  final String province;
  final String locality;
  final String fullAddress;
  final String countryCode;
  final String country;
  final String street;
  final String latitude;
  final String longitude;
  final String city;
  final String permissionStatus;

  bool get isValid =>
      latitude.isNotEmpty ||
      longitude.isNotEmpty ||
      fullAddress.isNotEmpty ||
      street.isNotEmpty ||
      city.isNotEmpty ||
      country.isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'province': province,
    'locality': locality,
    'fullAddress': fullAddress,
    'countryCode': countryCode,
    'country': country,
    'street': street,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'permissionStatus': permissionStatus,
  };

  factory DaliLocationSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return DaliLocationSnapshot(
      province: daliReportText(map['province']),
      locality: daliReportText(map['locality'] ?? map['subAdminArea']),
      fullAddress: daliReportText(map['fullAddress']),
      countryCode: daliReportText(map['countryCode']),
      country: daliReportText(map['country']),
      street: daliReportText(map['street']),
      latitude: daliReportText(map['latitude']),
      longitude: daliReportText(map['longitude']),
      city: daliReportText(map['city']),
      permissionStatus: daliReportText(map['permissionStatus']),
    );
  }
}

class DaliDeviceSnapshot {
  const DaliDeviceSnapshot({
    this.idfv = '',
    this.idfa = '',
    this.deviceId = '',
    this.riskDeviceId = '',
    this.batteryLevel = 0,
    this.isCharging = 0,
    this.elapsedMillis = 0,
    this.uptimeMillis = '0',
    this.isUsingProxy = 0,
    this.isUsingVpn = 0,
    this.isJailbroken = 0,
    this.isEmulator = 0,
    this.language = '',
    this.carrier = '',
    this.networkType = '',
    this.timeZoneName = '',
    this.cpuCoreCount = 0,
    this.brand = '',
    this.deviceName = '',
    this.model = '',
    this.modelName = '',
    this.systemVersion = '',
    this.packageName = '',
    this.screenHeight = 0,
    this.screenWidth = 0,
    this.screenSize = '',
    this.innerIp = '',
    this.currentWifiName = '',
    this.currentWifiBssid = '',
    this.wifiCount = 0,
    this.availableStorage = '0',
    this.totalStorage = '0',
    this.totalMemory = '0',
    this.availableMemory = '0',
    this.pushToken = '',
  });

  final String idfv;
  final String idfa;
  final String deviceId;
  final String riskDeviceId;
  final int batteryLevel;
  final int isCharging;
  final int elapsedMillis;
  final String uptimeMillis;
  final int isUsingProxy;
  final int isUsingVpn;
  final int isJailbroken;
  final int isEmulator;
  final String language;
  final String carrier;
  final String networkType;
  final String timeZoneName;
  final int cpuCoreCount;
  final String brand;
  final String deviceName;
  final String model;
  final String modelName;
  final String systemVersion;
  final String packageName;
  final int screenHeight;
  final int screenWidth;
  final String screenSize;
  final String innerIp;
  final String currentWifiName;
  final String currentWifiBssid;
  final int wifiCount;
  final String availableStorage;
  final String totalStorage;
  final String totalMemory;
  final String availableMemory;
  final String pushToken;

  factory DaliDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return DaliDeviceSnapshot(
      idfv: daliReportText(map['idfv']),
      idfa: daliReportText(map['idfa']),
      deviceId: daliReportText(map['deviceId']),
      riskDeviceId: daliReportText(map['riskDeviceId']),
      batteryLevel: _integer(map['batteryLevel']),
      isCharging: _integer(map['isCharging']),
      elapsedMillis: _integer(map['elapsedMillis']),
      uptimeMillis: daliReportText(map['uptimeMillis'], fallback: '0'),
      isUsingProxy: _integer(map['isUsingProxy']),
      isUsingVpn: _integer(map['isUsingVpn']),
      isJailbroken: _integer(map['isJailbroken']),
      isEmulator: _integer(map['isEmulator']),
      language: daliReportText(map['language']),
      carrier: daliReportText(map['carrier']),
      networkType: daliReportText(map['networkType']),
      timeZoneName: daliReportText(map['timeZoneName']),
      cpuCoreCount: _integer(map['cpuCoreCount']),
      brand: daliReportText(map['brand']),
      deviceName: daliReportText(map['deviceName']),
      model: daliReportText(map['model']),
      modelName: daliReportText(map['modelName']),
      systemVersion: daliReportText(map['systemVersion']),
      packageName: daliReportText(map['packageName']),
      screenHeight: _integer(map['screenHeight']),
      screenWidth: _integer(map['screenWidth']),
      screenSize: daliReportText(map['screenSize']),
      innerIp: daliReportText(map['innerIp']),
      currentWifiName: daliReportText(map['currentWifiName']),
      currentWifiBssid: daliReportText(map['currentWifiBssid']),
      wifiCount: _integer(map['wifiCount']),
      availableStorage: daliReportText(
        map['availableStorage'],
        fallback: '0',
      ),
      totalStorage: daliReportText(map['totalStorage'], fallback: '0'),
      totalMemory: daliReportText(map['totalMemory'], fallback: '0'),
      availableMemory: daliReportText(
        map['availableMemory'],
        fallback: '0',
      ),
      pushToken: daliReportText(map['pushToken']),
    );
  }
}

String encryptDaliDeviceReport({
  required DaliDeviceSnapshot snapshot,
  required DaliLocationSnapshot? location,
  required int lastLoginAtMillis,
  required int nowMillis,
  required String key,
  required String iv,
}) {
  final wifi = <String, dynamic>{
    'crocidolites': daliReportText(snapshot.currentWifiName),
    'eschars': daliReportText(snapshot.currentWifiBssid),
    'panbroil': daliReportText(snapshot.currentWifiBssid),
    'consols': daliReportText(snapshot.currentWifiName),
  };
  final payload = <String, dynamic>{
    'azuki': daliReportText(snapshot.systemVersion),
    'solum': lastLoginAtMillis,
    'iodisms': daliReportText(snapshot.packageName),
    'horsemen': <String, dynamic>{
      'meitnerium': snapshot.batteryLevel,
      'pincerlike': snapshot.isCharging,
    },
    'autohypnosis': <String, dynamic>{
      'toll': daliReportText(location?.longitude),
      'knolly': daliReportText(location?.latitude),
      'suppressor': daliReportText(location?.fullAddress),
      'pollinosis': <String, dynamic>{
        'twiggier': daliReportText(location?.country),
        'wealthiest': daliReportText(location?.countryCode),
        'prayerfulnesses': daliReportText(location?.province),
        'mastless': daliReportText(location?.city),
        'pereiopod': daliReportText(location?.locality),
        'psychobiology': daliReportText(location?.street),
      },
    },
    'murmurous': <String, dynamic>{
      'pithecoid': daliReportText(snapshot.idfv),
      'pyroxenoid': daliReportText(snapshot.idfa),
      'panbroil': daliReportText(snapshot.currentWifiBssid),
      'optimisation': nowMillis,
      'moulder': daliReportText(snapshot.uptimeMillis),
      'knifer': snapshot.isUsingProxy,
      'onomatologist': snapshot.isUsingVpn,
      'bumbling': snapshot.isJailbroken,
      'arbitrative': snapshot.isEmulator,
      'parainfluenza': daliReportText(snapshot.language),
      'exhalant': daliReportText(snapshot.carrier),
      'midwived': daliReportText(snapshot.networkType),
      'codirecting': const <dynamic>[],
      'fraudulently': daliReportText(snapshot.timeZoneName),
      'rato': snapshot.elapsedMillis,
    },
    'hesitate': <String, dynamic>{
      'droplet': daliReportText(snapshot.model),
      'bicycle': daliReportText(snapshot.brand),
      'anacondas': snapshot.cpuCoreCount,
      'uncounted': snapshot.screenHeight,
      'clerkly': daliReportText(snapshot.deviceName),
      'downward': snapshot.screenWidth,
      'bellow': daliReportText(snapshot.modelName),
      'beachwear': daliReportText(snapshot.screenSize),
      'reuse': daliReportText(snapshot.systemVersion),
    },
    'terminates': <String, dynamic>{
      'secretaryship': daliReportText(snapshot.innerIp),
      'advantageous': <dynamic>[wifi],
      'seed': wifi,
      'broadax': snapshot.wifiCount,
    },
    'homeric': <String, dynamic>{
      'pieties': daliReportText(snapshot.availableStorage),
      'polyneuritises': daliReportText(snapshot.totalStorage),
      'steatopygous': daliReportText(snapshot.totalMemory),
      'mimicking': daliReportText(snapshot.availableMemory),
    },
  };
  return ApiCrypto(key: key, iv: iv).encryptText(jsonEncode(payload));
}

String daliReportText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? fallback : text;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
