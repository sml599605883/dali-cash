import '../../core/json/json.dart';

class HomeData {
  HomeData({
    required this.loanOffer,
    required List<HomeBannerData> banners,
    required List<HomeRecommendationData> recommendations,
  }) : banners = List.unmodifiable(banners),
       recommendations = List.unmodifiable(recommendations);

  factory HomeData.fromJson(Json states) {
    HomeLoanOfferData? largeCard;
    HomeLoanOfferData? smallCard;
    final banners = <HomeBannerData>[];
    final recommendations = <HomeRecommendationData>[];

    for (final section in states['clingiest'].listValue) {
      if (section.mapOrNull == null) {
        continue;
      }

      final type = _string(section['sociologeses']);
      final items = section['jambes'].listOrNull;
      if (items == null) {
        continue;
      }

      switch (type) {
        case _HomeElementType.banner:
          banners.addAll(
            items
                .where((item) => item.mapOrNull != null)
                .map(HomeBannerData.fromJson),
          );
        case _HomeElementType.largeCard:
          largeCard ??= _firstLoanOffer(items);
        case _HomeElementType.smallCard:
          smallCard ??= _firstLoanOffer(items);
        case _HomeElementType.productList:
          recommendations.addAll(
            items
                .where((item) => item.mapOrNull != null)
                .map(HomeRecommendationData.fromJson),
          );
      }
    }

    return HomeData(
      loanOffer: largeCard ?? smallCard,
      banners: banners,
      recommendations: recommendations,
    );
  }

  final HomeLoanOfferData? loanOffer;
  final List<HomeBannerData> banners;
  final List<HomeRecommendationData> recommendations;
}

abstract final class _HomeElementType {
  static const banner = 'Coleseeds';
  static const largeCard = 'QuininaSpeculation';
  static const smallCard = 'Rattons';
  static const productList = 'Apocalypse';
}

class HomeLoanOfferData {
  const HomeLoanOfferData({
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.amount,
    required this.amountCaption,
    required this.loanTerm,
    required this.loanTermCaption,
    required this.interestRate,
    required this.interestRateCaption,
    required this.buttonText,
    required this.loanProcessText,
  });

  factory HomeLoanOfferData.fromJson(Json json) {
    return HomeLoanOfferData(
      productId: _string(json['underfeeding']),
      productName: _string(json['preslaughter']),
      productLogo: _string(json['creasing']),
      amount: _string(json['adapting']),
      amountCaption: _string(json['hotel']),
      loanTerm: _string(json['telfered']),
      loanTermCaption: _string(json['typefounder']),
      interestRate: _string(json['counterfeiters']),
      interestRateCaption: _string(json['euphonically']),
      buttonText: _string(json['weldor']),
      loanProcessText: _string(json['outgnaws']),
    );
  }

  final String productId;
  final String productName;
  final String productLogo;
  final String amount;
  final String amountCaption;
  final String loanTerm;
  final String loanTermCaption;
  final String interestRate;
  final String interestRateCaption;
  final String buttonText;
  final String loanProcessText;
}

class HomeBannerData {
  const HomeBannerData({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
  });

  factory HomeBannerData.fromJson(Json json) {
    return HomeBannerData(
      id: _string(json['underfeeding']),
      imageUrl: _string(json['ephemeras']),
      targetUrl: _string(json['millipede']),
    );
  }

  final String id;
  final String imageUrl;
  final String targetUrl;
}

class HomeRecommendationData {
  const HomeRecommendationData({
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.amount,
    required this.amountCaption,
    required this.interestRate,
    required this.loanTerm,
    required this.footer,
    required this.upscales,
  });

  factory HomeRecommendationData.fromJson(Json json) {
    return HomeRecommendationData(
      productId: _string(json['underfeeding']),
      productName: _string(json['preslaughter']),
      productLogo: _string(json['creasing']),
      amount: _string(json['adapting']),
      amountCaption: _string(json['hotel']),
      interestRate: _string(json['fishtailing']),
      loanTerm: _string(json['telfered']),
      footer: _joinTags(json['finos']),
      upscales: _int(json['upscales']),
    );
  }

  final String productId;
  final String productName;
  final String productLogo;
  final String amount;
  final String amountCaption;
  final String interestRate;
  final String loanTerm;
  final String footer;
  final int upscales;
}

String formatHomeAmount(String raw) {
  final match = RegExp(r'^(?:(₱|PHP *))?([0-9]+)(\.[0-9]+)?$').firstMatch(raw);
  if (match == null) {
    return raw;
  }

  final prefix = match.group(1) ?? '';
  final digits = match.group(2)!;
  final decimal = match.group(3) ?? '';
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return '$prefix$buffer$decimal';
}

HomeLoanOfferData? _firstLoanOffer(List<Json> items) {
  for (final item in items) {
    if (item.mapOrNull != null) {
      return HomeLoanOfferData.fromJson(item);
    }
  }
  return null;
}

String _string(Json json) {
  final value = json.value;
  return value is String ? value : '';
}

int _int(Json json) {
  final value = json.value;
  return value is int ? value : 0;
}

String _joinTags(Json json) {
  final tags = json.listOrNull;
  if (tags == null) {
    return '';
  }

  return tags
      .map((tag) => tag.value)
      .whereType<String>()
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .join(' / ');
}
