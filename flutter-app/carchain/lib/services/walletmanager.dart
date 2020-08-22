import 'package:carchain/models/wallet.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletManager with ChangeNotifier {
  String prefKey = 'privKey';
  SharedPreferences prefs;
  Wallet wallet;

  WalletManager() {
    wallet = null; // while waiting for loading prefs
    loadFromPrefs();
  }

  // toggle value of isDarkTheme
  void setWalletFromPrivKey(String privKey) {
    wallet = Wallet(privkey: privKey);
    saveToPrefs(privKey);
    notifyListeners();
  }

  Future<void> distroyWallet() async {
    wallet = null;
    await clearPrefs();
    notifyListeners();
  }

  // initialize shared preferences
  Future initPrefs() async {
    if (prefs == null) prefs = await SharedPreferences.getInstance();
  }

  // get value of isDarkTheme from prefs, by default true
  Future loadFromPrefs() async {
    await initPrefs();
    String privKey = prefs.getString(prefKey) ?? null;
    if (privKey != null) {
      wallet = Wallet(privkey: privKey);
    } else {
      wallet = null;
    }
    notifyListeners();
  }

  // save value of isDarkTheme to prefs
  Future saveToPrefs(String privKey) async {
    await initPrefs();
    prefs.setString(prefKey, privKey);
  }

  Future clearPrefs() async {
    await initPrefs();
    prefs.clear();
  }
}
