import 'package:vehicle_chain_app/util/shared.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRole {
  String key;
  String name;
  AppRole({this.key, this.name});
}

class AppSettings extends ChangeNotifier {
  // AppSetting variables
  SharedPreferences _prefs;
  String _prefRoleKey = 'appRole';
  AppRole activeAppRole;

  AppSettings() {
    activeAppRole = null;
    _loadAppSettingsFromPrefs();
  }

  Future initPrefs() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
  }

  Future _loadAppSettingsFromPrefs() async {
    await initPrefs();
    String activeRoleKey = _prefs.getString(_prefRoleKey) ?? 'user';
    activeAppRole = AppRole(key: activeRoleKey, name: appRoles[activeRoleKey]);
    notifyListeners();
  }

  // Pref Setters
  Future<void> _setAppSettingRole(String value) async {
    await _prefs.setString(_prefRoleKey, value);
  }

  // changers
  Future<void> changeAppSettingRole(String netName) async {
    await initPrefs();
    await _setAppSettingRole(netName);
    await _loadAppSettingsFromPrefs();
  }
}
