import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  ThemeMode get themeMode => _themeMode;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUser => _currentUser != null;

  // Setters
  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  set isLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  set errorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // User management
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> clearUser() async {
    _currentUser = null;
    notifyListeners();
  }

  // Theme management
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Load user from storage
  Future<void> loadUserFromStorage() async {
    try {
      isLoading = true;
      
      // Verificar si la caja está abierta
      if (!Hive.isBoxOpen('user_box')) {
        await Hive.openBox<User>('user_box');
      }
      
      final userBox = Hive.box<User>('user_box');
      final user = userBox.get('current_user');
      
      print('Loading user from storage: $user');
      
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        print('User loaded successfully: ${user.nombre}');
      } else {
        print('No user found in storage');
      }
    } catch (e) {
      print('Error loading user: $e');
      errorMessage = 'Error al cargar usuario: $e';
    } finally {
      isLoading = false;
    }
  }

  // Clear error
  void clearError() {
    errorMessage = null;
  }

  // Check if user needs to complete profile
  bool get needsProfile {
    return _currentUser == null;
  }
}
