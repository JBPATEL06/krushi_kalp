class TransactionModel {
  final int id;
  final int userId;
  final int testId;
  final double amount;
  final String status; // 'Success', 'Pending', 'Failed'
  final DateTime paymentDate;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.testId,
    required this.amount,
    required this.status,
    required this.paymentDate,
  });
}
