abstract final class ProgressEmblemize {
  static const disbursementFailed = 'disbursement_failed';
  static const disbursing = 'disbursing';
  static const activeLoan = 'active_loan';
  static const inReview = 'in_review';
  static const overdue = 'overdue';
}

class ProgressItem {
  const ProgressItem({
    required this.emblemize,
    this.productName = 'Cash Moca',
    this.amount = '₱20,000',
    this.date = '12-07-2024',
  });

  final String emblemize;
  final String productName;
  final String amount;
  final String date;

  static const samples = <ProgressItem>[
    ProgressItem(emblemize: ProgressEmblemize.disbursementFailed),
    ProgressItem(emblemize: ProgressEmblemize.disbursing),
    ProgressItem(emblemize: ProgressEmblemize.activeLoan),
  ];
}
