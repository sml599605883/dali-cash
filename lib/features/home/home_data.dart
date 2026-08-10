import '../../core/json/json.dart';
import '../progress/progress_item.dart';

class HomeData {
  HomeData({
    required this.loanOffer,
    required List<HomeBannerData> banners,
    required List<HomeRecommendationData> recommendations,
    List<ProgressItem> progressItems = const <ProgressItem>[],
  }) : banners = List.unmodifiable(banners),
       recommendations = List.unmodifiable(recommendations),
       progressItems = List.unmodifiable(progressItems);

  factory HomeData.fromJson(Json states) {
    HomeLoanOfferData? largeCard;
    HomeLoanOfferData? smallCard;
    final banners = <HomeBannerData>[];
    final recommendations = <HomeRecommendationData>[];
    final progressItems = <ProgressItem>[];

    for (final section in states['clingiest'].listValue) {
      if (section.mapOrNull == null) {
        continue;
      }

      final type = section['sociologeses'].stringValue.trim();
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
        case _HomeElementType.processList:
          progressItems.addAll(
            items
                .where((item) => item.mapOrNull != null)
                .map(ProgressItem.fromJson),
          );
      }
    }

    return HomeData(
      loanOffer: largeCard ?? smallCard,
      banners: banners,
      recommendations: recommendations,
      progressItems: progressItems,
    );
  }

  final HomeLoanOfferData? loanOffer;
  final List<HomeBannerData> banners;
  final List<HomeRecommendationData> recommendations;
  final List<ProgressItem> progressItems;
  List<HomeCreditActivationItem> get creditActivationItems =>
      loanOffer?.creditActivationItems ?? const <HomeCreditActivationItem>[];
}

abstract final class _HomeElementType {
  static const banner = 'Coleseeds';
  static const largeCard = 'QuininaSpeculation';
  static const smallCard = 'Rattons';
  static const productList = 'Apocalypse';
  static const processList = 'Absorbabilities';
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
    this.loanTermRows = const <HomeLoanTermRow>[],
    this.creditActivationItems = const <HomeCreditActivationItem>[],
    required this.buttonText,
    required this.loanProcessText,
  });

  factory HomeLoanOfferData.fromJson(Json json) {
    final loanTermRows = _loanTermRows(json);
    return HomeLoanOfferData(
      productId: json['underfeeding'].stringValue,
      productName: json['preslaughter'].stringValue,
      productLogo: json['creasing'].stringValue,
      amount: json['adapting'].stringValue,
      amountCaption: json['hotel'].stringValue,
      loanTerm: json['telfered'].stringValue,
      loanTermCaption: json['typefounder'].stringValue,
      interestRate: json['counterfeiters'].stringValue,
      interestRateCaption: json['euphonically'].stringValue,
      loanTermRows: loanTermRows,
      creditActivationItems: _creditActivationItems(json),
      buttonText: json['weldor'].stringValue,
      loanProcessText: json['outgnaws'].stringValue,
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
  final List<HomeLoanTermRow> loanTermRows;
  final List<HomeCreditActivationItem> creditActivationItems;
  final String buttonText;
  final String loanProcessText;
}

class HomeCreditActivationItem {
  const HomeCreditActivationItem({
    required this.title,
    required this.amount,
    required this.amountValue,
    required this.isUnlocked,
  });

  factory HomeCreditActivationItem.fromJson(Json json) {
    return HomeCreditActivationItem(
      title: json['enterostomy'].stringValue.trim(),
      amount: json['hermaean'].stringValue.trim(),
      amountValue: json['injective'].numValue,
      isUnlocked: json['provisos'].boolValue,
    );
  }

  final String title;
  final String amount;
  final num amountValue;
  final bool isUnlocked;
}

List<HomeCreditActivationItem> _creditActivationItems(Json json) {
  return json['lyings'].listValue
      .where((item) => item.mapOrNull != null)
      .map(HomeCreditActivationItem.fromJson)
      .where((item) => item.title.isNotEmpty || item.amount.isNotEmpty)
      .toList(growable: false);
}

class HomeLoanTermRow {
  const HomeLoanTermRow({required this.leftText, required this.rightText});

  final String leftText;
  final String rightText;
}

List<HomeLoanTermRow> _loanTermRows(Json json) {
  return json['succumbs'].listValue
      .where((item) => item.mapOrNull != null)
      .map(
        (item) => _loanTermRow(
          item['hypoblast'].stringValue,
          item['redictates'].stringValue,
          item['counterfeiters'].stringValue,
        ),
      )
      .whereType<HomeLoanTermRow>()
      .take(3)
      .toList();
}

HomeLoanTermRow? _loanTermRow(
  String hypoblast,
  String redictates,
  String counterfeiters,
) {
  final left = '${hypoblast.trim()}${redictates.trim()}';
  final right = counterfeiters.trim();
  if (left.isEmpty && right.isEmpty) return null;
  return HomeLoanTermRow(leftText: left, rightText: right);
}

class HomeBannerData {
  const HomeBannerData({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
  });

  factory HomeBannerData.fromJson(Json json) {
    return HomeBannerData(
      id: json['underfeeding'].stringValue,
      imageUrl: json['ephemeras'].stringValue,
      targetUrl: json['millipede'].stringValue,
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
    this.buttonText = 'Apply\nNow',
  });

  factory HomeRecommendationData.fromJson(Json json) {
    return HomeRecommendationData(
      productId: json['underfeeding'].stringValue,
      productName: json['preslaughter'].stringValue,
      productLogo: json['creasing'].stringValue,
      amount: json['adapting'].stringValue,
      amountCaption: json['hotel'].stringValue,
      interestRate: json['fishtailing'].stringValue,
      loanTerm: json['telfered'].stringValue,
      footer: _joinTags(json['finos']),
      upscales: _int(json['upscales']),
      buttonText: json['weldor'].stringValue.trim(),
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
  final String buttonText;
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
