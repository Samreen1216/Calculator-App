import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation.dart';

class HistoryService {
  final List<Calculation> _history = [];
  static const int _maxHistory = 100;
  static const String _storageKey = 'calculator_history_v1';
  bool _isInitialized = false;

  List<Calculation> get history => List.unmodifiable(_history);
  bool get isEmpty => _history.isEmpty;
  int get length => _history.length;
  bool get isInitialized => _isInitialized;

  /// Initializes the service and loads persisted history from local storage.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? storedJsonList = prefs.getStringList(_storageKey);
      if (storedJsonList != null) {
        _history.clear();
        for (final item in storedJsonList) {
          try {
            final Map<String, dynamic> map = jsonDecode(item) as Map<String, dynamic>;
            _history.add(Calculation.fromJson(map));
          } catch (_) {
            // Skip corrupted entries
          }
        }
      }
    } catch (_) {
      // In testing environments or when storage is unavailable, continue in-memory
    } finally {
      _isInitialized = true;
    }
  }

  /// Adds a calculation to history and persists the update.
  Future<void> addCalculation(Calculation calculation) async {
    _history.insert(0, calculation);
    if (_history.length > _maxHistory) {
      _history.removeLast();
    }
    await _persist();
  }

  /// Inserts a calculation at [index] and persists the update.
  Future<void> insertAt(int index, Calculation calculation) async {
    final targetIndex = index.clamp(0, _history.length);
    _history.insert(targetIndex, calculation);
    if (_history.length > _maxHistory) {
      _history.removeLast();
    }
    await _persist();
  }

  /// Removes a single calculation at [index] and persists the update.
  Future<void> removeAt(int index) async {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      await _persist();
    }
  }

  /// Clears all calculation history from memory and persistent storage.
  Future<void> clear() async {
    _history.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {
      // Storage unavailable
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encodedList = _history.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_storageKey, encodedList);
    } catch (_) {
      // Storage unavailable
    }
  }
}
