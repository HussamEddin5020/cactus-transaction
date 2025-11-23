enum TransactionStatus {
  success,
  rejected,
  pending,
}

class Transaction {
  final String id;
  final String code;
  final String merchantId;
  final String terminalId;
  final double amount;
  final TransactionStatus status;
  final String date;
  final String time;
  final String cardNumber;
  final String customerName;
  final String customerNameEn;

  Transaction({
    required this.id,
    required this.code,
    required this.merchantId,
    required this.terminalId,
    required this.amount,
    required this.status,
    required this.date,
    required this.time,
    required this.cardNumber,
    required this.customerName,
    required this.customerNameEn,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      code: json['code'] as String,
      merchantId: json['merchantId'] as String,
      terminalId: json['terminalId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: _parseStatus(json['status'] as String),
      date: json['date'] as String,
      time: json['time'] as String,
      cardNumber: json['cardNumber'] as String,
      customerName: json['customerName'] as String,
      customerNameEn: json['customerNameEn'] as String,
    );
  }

  static TransactionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return TransactionStatus.success;
      case 'rejected':
        return TransactionStatus.rejected;
      case 'pending':
        return TransactionStatus.pending;
      default:
        return TransactionStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case TransactionStatus.success:
        return 'success';
      case TransactionStatus.rejected:
        return 'rejected';
      case TransactionStatus.pending:
        return 'pending';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'merchantId': merchantId,
      'terminalId': terminalId,
      'amount': amount,
      'status': statusString,
      'date': date,
      'time': time,
      'cardNumber': cardNumber,
      'customerName': customerName,
      'customerNameEn': customerNameEn,
    };
  }
}

