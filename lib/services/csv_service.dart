import 'package:csv/csv.dart';
import '../models/transaction.dart';
import '../models/merchant.dart';
import 'language_service.dart';

class CsvService {
  static String exportTransactionsToCsv(
    List<Transaction> transactions,
    LanguageService languageService,
  ) {
    final List<List<dynamic>> rows = [];
    
    // Header
    if (languageService.locale.languageCode == 'ar') {
      rows.add([
        'كود العملية',
        'التاجر',
        'الماكينة',
        'المبلغ',
        'الحالة',
        'التاريخ',
        'الوقت',
        'رقم البطاقة',
        'اسم العميل',
      ]);
    } else {
      rows.add([
        'Transaction Code',
        'Merchant',
        'Terminal',
        'Amount',
        'Status',
        'Date',
        'Time',
        'Card Number',
        'Customer Name',
      ]);
    }

    // Data rows
    for (var transaction in transactions) {
      final status = languageService.locale.languageCode == 'ar'
          ? _getStatusAr(transaction.status)
          : _getStatusEn(transaction.status);
      
      final customerName = languageService.locale.languageCode == 'ar'
          ? transaction.customerName
          : transaction.customerNameEn;

      rows.add([
        transaction.code,
        transaction.merchantId,
        transaction.terminalId,
        transaction.amount.toStringAsFixed(2),
        status,
        transaction.date,
        transaction.time,
        transaction.cardNumber,
        customerName,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static String exportMerchantsToCsv(
    List<Merchant> merchants,
    LanguageService languageService,
  ) {
    final List<List<dynamic>> rows = [];
    
    // Header
    if (languageService.locale.languageCode == 'ar') {
      rows.add([
        'كود التاجر',
        'الاسم',
        'الهاتف',
        'البريد الإلكتروني',
        'عدد الماكينات',
      ]);
    } else {
      rows.add([
        'Merchant Code',
        'Name',
        'Phone',
        'Email',
        'Terminals Count',
      ]);
    }

    // Data rows
    for (var merchant in merchants) {
      final name = languageService.locale.languageCode == 'ar'
          ? merchant.name
          : merchant.nameEn;

      rows.add([
        merchant.code,
        name,
        merchant.phone,
        merchant.email,
        merchant.terminals.length.toString(),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static String _getStatusAr(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'نجحت';
      case TransactionStatus.rejected:
        return 'مرفوضة';
      case TransactionStatus.pending:
        return 'معلقة';
    }
  }

  static String _getStatusEn(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.rejected:
        return 'Rejected';
      case TransactionStatus.pending:
        return 'Pending';
    }
  }
}

