import '../../core/json/json.dart';

abstract final class ProgressEmblemize {
  static const unknown = 0;
  static const inReview = 1;
  static const activeLoan = 2;
  static const overdue = 3;
  static const disbursing = 4;
  static const disbursementFailed = 5;
  static const disbursementFailedAlternative = 6;
}

class ProgressItem {
  const ProgressItem({
    required this.emblemize,
    this.orderNumber = '',
    this.productId = '',
    this.productName = 'Cash Moca',
    this.productLogo = '',
    this.amount = '₱20,000',
    this.amountLabel = 'Loan Amount',
    this.date = '12-07-2024',
    this.dateLabel = 'Loan Date',
    this.statusLabel = '',
    this.detailRoute = '',
    this.actions = const <ProgressAction>[],
    this.usesServerActions = false,
  });

  factory ProgressItem.fromJson(Json json) {
    final formattedAmount = json['alternation'].stringValue.trim();
    return ProgressItem(
      orderNumber: json['titled'].stringValue.trim(),
      productId: json['highlands'].stringValue.trim(),
      productName: json['studdies'].stringValue.trim(),
      productLogo: json['tricky'].stringValue.trim(),
      amount: formattedAmount.isNotEmpty
          ? formattedAmount
          : json['injective'].stringValue.trim(),
      amountLabel: json['betattered'].stringValue.trim(),
      date: json['totalist'].stringValue.trim(),
      dateLabel: json['relativize'].stringValue.trim(),
      emblemize: json['emblemize'].intValue,
      statusLabel: json['interterm'].stringValue.trim(),
      detailRoute: json['millipede'].stringValue.trim(),
      actions: List<ProgressAction>.unmodifiable(
        json['psychographs'].listValue
            .where((item) => item.mapOrNull != null)
            .map(ProgressAction.fromJson)
            .where((action) => action.visible),
      ),
      usesServerActions: true,
    );
  }

  final int emblemize;
  final String orderNumber;
  final String productId;
  final String productName;
  final String productLogo;
  final String amount;
  final String amountLabel;
  final String date;
  final String dateLabel;
  final String statusLabel;
  final String detailRoute;
  final List<ProgressAction> actions;
  final bool usesServerActions;

  static const samples = <ProgressItem>[
    ProgressItem(emblemize: ProgressEmblemize.disbursementFailed),
    ProgressItem(emblemize: ProgressEmblemize.disbursing),
    ProgressItem(emblemize: ProgressEmblemize.activeLoan),
  ];
}

class ProgressAction {
  const ProgressAction({
    required this.type,
    required this.visible,
    required this.label,
    required this.badge,
    required this.route,
  });

  factory ProgressAction.fromJson(Json json) {
    return ProgressAction(
      type: json['sociologeses'].stringValue.trim(),
      visible: json['deloused'].intValue == 1,
      label: json['barbeque'].stringValue.trim(),
      badge: json['rowboat'].stringValue.trim(),
      route: json['ailing'].stringValue.trim(),
    );
  }

  final String type;
  final bool visible;
  final String label;
  final String badge;
  final String route;
}
