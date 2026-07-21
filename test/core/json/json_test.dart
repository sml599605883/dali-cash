import 'dart:convert';

import 'package:dali_cash/core/json/json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid json returns null-safe values', () {
    final json = Json.parse('{invalid');

    expect(json.isNull(), isTrue);
    expect(json['missing'].stringValue, '');
    expect(json.listValue, isEmpty);
    expect(json.mapValue, isEmpty);
  });

  test('reads nested values with tolerant conversions', () {
    final json = Json({
      'count': '12',
      'ratio': 2.5,
      'enabled': 'yes',
      'items': [
        {'name': 'Dali'},
      ],
    });

    expect(json['count'].intValue, 12);
    expect(json['ratio'].doubleValue, 2.5);
    expect(json['enabled'].boolValue, isTrue);
    expect(json['items'][0]['name'].stringValue, 'Dali');
  });

  test('supports mutation removal and serialization', () {
    final json = Json(<String, dynamic>{});

    json['name'] = 'Dali';
    json['items'] = [1, 2];
    json['items'][2] = 3;
    json.remove('name');

    expect(json['name'].exists(), isFalse);
    expect(json['items'].rawListValue, [1, 2, 3]);
    expect(Json.parse(json.rawString())['items'][2].intValue, 3);
    expect(json.prettyPrint, contains('\n'));
  });

  test('parseBytes handles utf8 json', () {
    final json = Json.parseBytes(utf8.encode('{"message":"你好"}'));

    expect(json['message'].stringValue, '你好');
  });
}
