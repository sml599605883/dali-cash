import 'package:dali_cash/app/navigation/dali_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DaliDeepLinkParser();

  test('parses the Dali product detail scheme and product id', () {
    final target = parser.parse('ph://dali-cash/ios/Conifer?highlands=2');

    expect(target.kind, DaliDeepLinkKind.productDetail);
    expect(target.alias, 'Conifer');
    expect(target.productId, '2');
  });

  test('uses response arguments when a detail scheme has no product id', () {
    final target = parser.parse(
      'ph://dali-cash/ios/Conifer',
      arguments: {'highlands': 7},
    );

    expect(target.kind, DaliDeepLinkKind.productDetail);
    expect(target.productId, '7');
  });

  test('reads the documented order status field from scheme and arguments', () {
    expect(
      parser
          .parse('ph://dali-cash/ios/Luminance?anfractuosity=7')
          .orderStatusCode,
      '7',
    );
    expect(
      parser
          .parse('Luminance', arguments: {'anfractuosity': 6})
          .orderStatusCode,
      '6',
    );
  });

  test('maps the documented Dali navigation aliases', () {
    expect(
      parser.parse('ph://dali-cash/ios/Personation').kind,
      DaliDeepLinkKind.home,
    );
    expect(
      parser.parse('ph://dali-cash/ios/VeinedYachting').kind,
      DaliDeepLinkKind.mine,
    );
    expect(
      parser.parse('ph://dali-cash/ios/TortoiseBerkelium').kind,
      DaliDeepLinkKind.login,
    );
    expect(
      parser.parse('ph://dali-cash/ios/Luminance').kind,
      DaliDeepLinkKind.order,
    );
    expect(
      parser.parse('ph://dali-cash/ios/Mateys?highlands=2').kind,
      DaliDeepLinkKind.admission,
    );
    expect(
      parser.parse('ph://dali-cash/ios/Heed?highlands=2').kind,
      DaliDeepLinkKind.recredit,
    );
  });

  test('separates deferred web content from unsupported Dali targets', () {
    expect(
      parser.parse('https://example.test/help').kind,
      DaliDeepLinkKind.webView,
    );
    expect(
      parser.parse('ph://dali-cash/ios/UnknownPage').kind,
      DaliDeepLinkKind.unsupportedDali,
    );
  });
}
