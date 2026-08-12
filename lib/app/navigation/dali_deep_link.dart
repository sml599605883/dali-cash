enum DaliDeepLinkKind {
  home,
  mine,
  login,
  order,
  productDetail,
  admission,
  recredit,
  unavailable,
  webView,
  unsupportedDali,
  unsupported,
}

class DaliDeepLink {
  const DaliDeepLink({
    required this.kind,
    required this.alias,
    this.uri,
    this.arguments,
  });

  final DaliDeepLinkKind kind;
  final String alias;
  final Uri? uri;
  final Object? arguments;

  String get productId {
    final fromQuery = uri?.queryParameters['highlands']?.trim() ?? '';
    if (fromQuery.isNotEmpty) {
      return fromQuery;
    }
    if (arguments is Map) {
      final value = (arguments as Map)['highlands'];
      return value?.toString().trim() ?? '';
    }
    return '';
  }

  String get orderStatusCode {
    final fromQuery = uri?.queryParameters['anfractuosity']?.trim() ?? '';
    if (fromQuery.isNotEmpty) {
      return fromQuery;
    }
    if (arguments is Map) {
      final value = (arguments as Map)['anfractuosity'];
      return value?.toString().trim() ?? '';
    }
    return '';
  }
}

class DaliDeepLinkParser {
  const DaliDeepLinkParser();

  static const _scheme = 'ph';
  static const _host = 'dali-cash';
  static const _platform = 'ios';

  DaliDeepLink parse(String rawTarget, {Object? arguments}) {
    final target = rawTarget.trim();
    if (target.isEmpty) {
      return const DaliDeepLink(kind: DaliDeepLinkKind.unsupported, alias: '');
    }

    final directKind = _kindForAlias(target);
    if (directKind != null) {
      return DaliDeepLink(
        kind: directKind,
        alias: target,
        arguments: arguments,
      );
    }

    final uri = Uri.tryParse(target);
    if (uri == null) {
      return DaliDeepLink(
        kind: DaliDeepLinkKind.unsupported,
        alias: target,
        arguments: arguments,
      );
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return DaliDeepLink(
        kind: DaliDeepLinkKind.webView,
        alias: target,
        uri: uri,
        arguments: arguments,
      );
    }
    if (_isDaliScheme(uri)) {
      for (final segment in uri.pathSegments.reversed) {
        if (segment == _platform) {
          continue;
        }
        final kind = _kindForAlias(segment.trim());
        if (kind != null) {
          return DaliDeepLink(
            kind: kind,
            alias: segment.trim(),
            uri: uri,
            arguments: arguments,
          );
        }
      }
      return DaliDeepLink(
        kind: DaliDeepLinkKind.unsupportedDali,
        alias: target,
        uri: uri,
        arguments: arguments,
      );
    }

    final page = uri.queryParameters['appPage'] ?? uri.queryParameters['page'];
    final kind = page == null ? null : _kindForAlias(page.trim());
    if (kind == null) {
      return DaliDeepLink(
        kind: DaliDeepLinkKind.unsupported,
        alias: target,
        uri: uri,
        arguments: arguments,
      );
    }
    return DaliDeepLink(
      kind: kind,
      alias: page!.trim(),
      uri: uri,
      arguments: arguments,
    );
  }

  DaliDeepLinkKind? _kindForAlias(String alias) {
    return switch (alias) {
      'main' || 'Personation' => DaliDeepLinkKind.home,
      'setting' || 'VeinedYachting' => DaliDeepLinkKind.mine,
      '/login' || 'login' || 'TortoiseBerkelium' => DaliDeepLinkKind.login,
      'order' || 'Luminance' => DaliDeepLinkKind.order,
      'productDetail' || 'Conifer' => DaliDeepLinkKind.productDetail,
      'apiRemindUrl' || 'Mateys' => DaliDeepLinkKind.admission,
      'recredit' || 'Heed' => DaliDeepLinkKind.recredit,
      _ => null,
    };
  }

  bool _isDaliScheme(Uri uri) {
    return uri.scheme == _scheme &&
        uri.host == _host &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == _platform;
  }
}
