import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotifierService extends ChangeNotifier {
  SharedPreferences prefs;
  bool isSetupWallet;

  NotifierService() {
    isSetupWallet = false; // while waiting for loading prefs
    loadFromPrefs();
  }
  // initialize shared preferences
  Future initPrefs() async {
    if (prefs == null) prefs = await SharedPreferences.getInstance();
  }

  Future loadFromPrefs() async {
    await initPrefs();
    isSetupWallet =
        prefs.getBool('didSetupWallet') ?? false; // didSetupWallet()
    notifyListeners();
  }

  void updateNotifier() {
    notifyListeners();
  }
}
