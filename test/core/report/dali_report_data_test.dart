import 'dart:convert';

import 'package:dali_cash/core/network/api_crypto.dart';
import 'package:dali_cash/core/report/dali_report_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const location = DaliLocationSnapshot(
    province: 'Metro Manila',
    locality: 'Bel-Air',
    fullAddress: 'Ayala Avenue, Makati',
    countryCode: 'PH',
    country: 'Philippines',
    street: 'Ayala Avenue',
    latitude: '14.5547',
    longitude: '121.0244',
    city: 'Makati',
    permissionStatus: 'authorized_when_in_use',
  );
  const snapshot = DaliDeviceSnapshot(
    idfv: 'idfv-1',
    idfa: 'idfa-1',
    riskDeviceId: 'risk-1',
    batteryLevel: 75,
    isCharging: 1,
    elapsedMillis: 42,
    uptimeMillis: '1000',
    isUsingProxy: 1,
    isUsingVpn: 1,
    language: 'en',
    carrier: 'Globe',
    networkType: 'WIFI',
    timeZoneName: 'GMT+8',
    cpuCoreCount: 6,
    brand: 'Apple',
    deviceName: 'Juan iPhone',
    model: 'iPhone17,1',
    modelName: 'native-model-name',
    systemVersion: '18.0',
    packageName: 'com.dali.cash',
    screenHeight: 2556,
    screenWidth: 1179,
    screenSize: '6.3',
    innerIp: '192.168.1.2',
    currentWifiName: 'Home',
    currentWifiBssid: 'aa:bb:cc:dd:ee:ff',
    wifiCount: 1,
    availableStorage: '100',
    totalStorage: '200',
    totalMemory: '300',
    availableMemory: '150',
  );

  test('parses Dali native location and device values', () {
    final parsedLocation = DaliLocationSnapshot.fromMap(location.toMap());
    final parsedDevice = DaliDeviceSnapshot.fromMap(const <String, Object?>{
      'idfv': 'idfv-1',
      'batteryLevel': 75,
      'screenWidth': 1179,
    });

    expect(parsedLocation.isValid, isTrue);
    expect(parsedLocation.city, 'Makati');
    expect(parsedDevice.idfv, 'idfv-1');
    expect(parsedDevice.batteryLevel, 75);
    expect(parsedDevice.screenWidth, 1179);
    expect(DaliLocationSnapshot.fromMap(const {}).isValid, isFalse);
  });

  test('encrypts the documented Dali device payload', () {
    const key = 'ba927fc9e96f9676';
    const iv = '16f7ddfc7aef7a2e';
    final encrypted = encryptDaliDeviceReport(
      snapshot: snapshot,
      deviceModel: 'iPhone 16 Pro',
      physicalSize: '6.3',
      location: location,
      lastLoginAtMillis: 1234,
      nowMillis: 5678,
      key: key,
      iv: iv,
    );
    final payload =
        jsonDecode(ApiCrypto(key: key, iv: iv).decryptText(encrypted))
            as Map<String, dynamic>;

    expect(payload.containsKey('oxidising'), isFalse);
    expect(payload['azuki'], '18.0');
    expect(payload['solum'], 1234);
    expect(payload['iodisms'], 'com.dali.cash');
    expect(payload['horsemen']['meitnerium'], 75);
    expect(payload['autohypnosis']['toll'], '121.0244');
    expect(payload['autohypnosis']['pollinosis']['mastless'], 'Makati');
    expect(payload['murmurous']['pithecoid'], 'idfv-1');
    expect(payload['murmurous']['optimisation'], 5678);
    expect(payload['murmurous']['onomatologist'], 1);
    expect(payload['murmurous']['fraudulently'], 'GMT+8');
    expect(payload['hesitate'].containsKey('droplet'), isFalse);
    expect(payload['hesitate']['bellow'], 'iPhone 16 Pro');
    expect(payload['hesitate']['beachwear'], '6.3');
    expect(payload['terminates']['seed']['crocidolites'], 'Home');
    expect(payload['homeric']['polyneuritises'], '200');
  });
}
