import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isMerchant => _currentUser?.role == UserRole.merchant;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Test credentials
    if (username == 'admin' && password == 'admin') {
      _currentUser = User.admin(
        id: 'admin1',
        username: 'admin',
        email: 'admin@example.com',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (username.startsWith('merchant') && password == 'merchant') {
      // Extract merchant ID from username (e.g., merchant1 -> MER001)
      final merchantId = username.replaceAll('merchant', 'MER00');
      _currentUser = User.merchant(
        id: 'user1',
        username: username,
        email: '$username@example.com',
        merchantId: merchantId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

