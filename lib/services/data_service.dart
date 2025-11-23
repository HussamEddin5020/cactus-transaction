import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/merchant.dart';
import '../models/terminal.dart';
import '../models/transaction.dart';

class DataService {
  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();

  DataService._();

  List<Merchant>? _merchants;
  List<Terminal>? _terminals;
  List<Transaction>? _transactions;

  Future<void> loadData() async {
    try {
      String jsonString = '';

      // For web, try loading via HTTP first, fallback to rootBundle
      if (kIsWeb) {
        try {
          // Try multiple possible paths for web
          final paths = [
            '/assets/data/test_data.json',
            'assets/data/test_data.json',
            'packages/cactus_dashboard_flutter_web/assets/data/test_data.json',
          ];

          bool loaded = false;
          for (final path in paths) {
            try {
              final response = await http.get(Uri.parse(path));
              if (response.statusCode == 200) {
                jsonString = response.body;
                loaded = true;
                break;
              }
            } catch (e) {
              continue;
            }
          }

          if (!loaded) {
            // Fallback to rootBundle
            jsonString = await rootBundle.loadString(
              'assets/data/test_data.json',
            );
          }
        } catch (e) {
          // Fallback to rootBundle if HTTP fails
          jsonString = await rootBundle.loadString(
            'assets/data/test_data.json',
          );
        }
      } else {
        jsonString = await rootBundle.loadString('assets/data/test_data.json');
      }

      // Ensure jsonString is not empty before decoding
      if (jsonString.isEmpty) {
        debugPrint('Error: JSON string is empty');
        return;
      }

      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _merchants = (jsonData['merchants'] as List)
          .map((json) => Merchant.fromJson(json))
          .toList();

      _terminals = (jsonData['terminals'] as List)
          .map((json) => Terminal.fromJson(json))
          .toList();

      _transactions = (jsonData['transactions'] as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  List<Merchant> get merchants => _merchants ?? [];
  List<Terminal> get terminals => _terminals ?? [];
  List<Transaction> get transactions => _transactions ?? [];

  List<Terminal> getTerminalsByMerchant(String merchantId) {
    return _terminals?.where((t) => t.merchantId == merchantId).toList() ?? [];
  }

  List<Transaction> getTransactionsByMerchant(String merchantId) {
    return _transactions?.where((t) => t.merchantId == merchantId).toList() ??
        [];
  }

  List<Transaction> getTransactionsByTerminal(String terminalId) {
    return _transactions?.where((t) => t.terminalId == terminalId).toList() ??
        [];
  }

  Merchant? getMerchantById(String merchantId) {
    return _merchants?.firstWhere((m) => m.id == merchantId);
  }

  Terminal? getTerminalById(String terminalId) {
    return _terminals?.firstWhere((t) => t.id == terminalId);
  }

  List<Merchant> searchMerchants(String query) {
    if (query.isEmpty) return merchants;
    final lowerQuery = query.toLowerCase();
    return merchants.where((merchant) {
      return merchant.name.toLowerCase().contains(lowerQuery) ||
          merchant.nameEn.toLowerCase().contains(lowerQuery) ||
          merchant.code.toLowerCase().contains(lowerQuery) ||
          merchant.phone.contains(query) ||
          merchant.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
