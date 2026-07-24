import 'package:dali_cash/features/certification/identity_confirmation/identity_recognition_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses identity recognition fields from upload response data', () {
    final result = IdentityRecognitionResult.fromMap({
      'crocidolites': 'SIMBAJON JR ROLANDO MAESTRE',
      'imputes': '0111-9695505-5',
      'elderlies': '',
      'annealers': '1995/05/31',
      'millipede': 'https://example.com/id-card.jpg',
      'repellers': '1995',
      'nonevent': '05',
      'pectoral': '31',
    });

    expect(result.fullName, 'SIMBAJON JR ROLANDO MAESTRE');
    expect(result.idNumber, '0111-9695505-5');
    expect(result.dateOfBirth, '1995/05/31');
    expect(result.imageUrl, 'https://example.com/id-card.jpg');
    expect(result.elderlies, '');
    expect(result.year, '1995');
    expect(result.month, '05');
    expect(result.day, '31');
  });

  test('uses empty strings when recognition fields are absent', () {
    final result = IdentityRecognitionResult.fromMap(const {});

    expect(result.fullName, '');
    expect(result.idNumber, '');
    expect(result.dateOfBirth, '');
    expect(result.imageUrl, '');
  });
}
