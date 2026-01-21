import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _killSwitch = true;
  bool _autoConnect = false;
  bool _showNotification = true;
  bool _splitTunneling = false;
  List<String> _excludedApps = [];
  bool _isLoading = true;
  
  bool get killSwitch => _killSwitch;
  bool get autoConnect => _autoConnect;
  bool get showNotification => _showNotification;
  bool get splitTunneling => _splitTunneling;
  List<String> get excludedApps => _excludedApps;
  bool get isLoading => _isLoading;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _killSwitch = prefs.getBool('killSwitch') ?? true;
      _autoConnect = prefs.getBool('autoConnect') ?? false;
      _showNotification = prefs.getBool('showNotification') ?? true;
      _splitTunneling = prefs.getBool('splitTunneling') ?? false;
      _excludedApps = prefs.getStringList('excludedApps') ?? [];
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('killSwitch', _killSwitch);
      await prefs.setBool('autoConnect', _autoConnect);
      await prefs.setBool('showNotification', _showNotification);
      await prefs.setBool('splitTunneling', _splitTunneling);
      await prefs.setStringList('excludedApps', _excludedApps);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }
  
  Future<void> setKillSwitch(bool value) async {
    _killSwitch = value;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> setAutoConnect(bool value) async {
    _autoConnect = value;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> setShowNotification(bool value) async {
    _showNotification = value;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> setSplitTunneling(bool value) async {
    _splitTunneling = value;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> setExcludedApps(List<String> apps) async {
    _excludedApps = apps;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> addExcludedApp(String packageName) async {
    if (!_excludedApps.contains(packageName)) {
      _excludedApps.add(packageName);
      notifyListeners();
      await _saveSettings();
    }
  }
  
  Future<void> removeExcludedApp(String packageName) async {
    _excludedApps.remove(packageName);
    notifyListeners();
    await _saveSettings();
  }
}
