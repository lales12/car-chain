import 'package:carchain/app_config.dart';
import 'package:carchain/models/AppUserWallet.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

class WalletManager with ChangeNotifier {
  String prefKey = 'privKey';
  SharedPreferences prefs;
  AppUserWallet appUserWallet;

  final client = Web3Client(configParams.rpcUrl, Client());

  WalletManager() {
    appUserWallet = null; // while waiting for loading prefs
    loadFromPrefs();
  }

  Stream<AppUserWallet> appUserWalletStream() async* {
    if (appUserWallet != null) {
      final credentials =
          await client.credentialsFromPrivateKey(appUserWallet.privkey);
      final address = await credentials.extractAddress();
      appUserWallet.balance = await client.getBalance(address);
      yield appUserWallet;
    }
  }

  void setWalletFromPrivKey(String privKey) {
    appUserWallet = AppUserWallet(privkey: privKey);
    saveToPrefs(privKey);
    notifyListeners();
  }

  Future<void> distroyWallet() async {
    appUserWallet = null;
    await clearPrefs();
    notifyListeners();
  }

  // initialize shared preferences
  Future initPrefs() async {
    if (prefs == null) prefs = await SharedPreferences.getInstance();
  }

  Future loadFromPrefs() async {
    await initPrefs();
    String privKey = prefs.getString(prefKey) ?? null;
    if (privKey != null) {
      appUserWallet = AppUserWallet(privkey: privKey);
    } else {
      appUserWallet = null;
    }
    notifyListeners();
  }

  Future saveToPrefs(String privKey) async {
    await initPrefs();
    prefs.setString(prefKey, privKey);
  }

  Future clearPrefs() async {
    await initPrefs();
    prefs.clear();
  }
}
