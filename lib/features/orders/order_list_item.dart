import 'package:dali_cash/core/json/json.dart';

enum MineOrderStatus {
  all('4', 'View All'),
  unpaid('7', 'Unpaid'),
  late('6', 'Late'),
  paid('5', 'Paid');

  const MineOrderStatus(this.code, this.label);

  final String code;
  final String label;

  static MineOrderStatus fromCode(String? code) {
    return values.firstWhere(
      (status) => status.code == code?.trim(),
      orElse: () => all,
    );
  }
}

class OrderListItem {
  const OrderListItem({
    required this.orderId,
    required this.orderNo,
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.statusCode,
    required this.statusText,
    required this.amountText,
    required this.amountLabel,
    required this.actionText,
    required this.actionTarget,
    required this.dateLabel,
    required this.dateValue,
    required this.overdueDays,
  });

  factory OrderListItem.fromJson(Json json) {
    return OrderListItem(
      orderId: json['filers'].stringValue.trim(),
      orderNo: json['saggards'].stringValue.trim(),
      productId: json['thunderstruck'].stringValue.trim(),
      productName: json['preslaughter'].stringValue.trim(),
      productLogo: json['creasing'].stringValue.trim(),
      statusCode: json['fornices'].intValue,
      statusText: json['proboscis'].stringValue.trim(),
      amountText: json['injective'].stringValue.trim(),
      amountLabel: json['planetological'].stringValue.trim(),
      actionText: json['weldor'].stringValue.trim(),
      actionTarget: json['nauseant'].stringValue.trim(),
      dateLabel: json['prebiological'].stringValue.trim(),
      dateValue: json['en'].stringValue.trim(),
      overdueDays: json['reshippers'].intValue,
    );
  }

  final String orderId;
  final String orderNo;
  final String productId;
  final String productName;
  final String productLogo;
  final int statusCode;
  final String statusText;
  final String amountText;
  final String amountLabel;
  final String actionText;
  final String actionTarget;
  final String dateLabel;
  final String dateValue;
  final int overdueDays;

  bool get showAction => statusCode == 174 || statusCode == 180;

  bool get usesBlueAction => statusCode == 174;

  bool get usesRedAction => statusCode == 180;
}

List<OrderListItem> parseOrderListItems(Json states) {
  return states['clingiest'].listValue
      .where((row) => row.mapOrNull != null)
      .map(OrderListItem.fromJson)
      .toList(growable: false);
}
