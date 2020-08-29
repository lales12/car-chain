import 'dart:developer';

import 'package:carchain/app_config.dart';
import 'package:carchain/models/AppUserWallet.dart';
import 'package:flutter/material.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;

class WalletManager with ChangeNotifier {
  String _prefPrivKey = 'privKey';
  String _prefMnemonicKey = 'mnemonic';
  String _prefIsMnemonicKey = 'isMnemonic';
  SharedPreferences _prefs;

  bool isWalletTypeMnemonic = false;
  AppUserWallet appUserWallet;

  final client = Web3Client(configParams.rpcUrl, Client());

  WalletManager() {
    appUserWallet = null; // while waiting for loading prefs
    _loadFromPrefs();
  }

  Future initPrefs() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
  }

  Future _loadFromPrefs() async {
    await initPrefs();
    // get type of wallet
    bool isMnemonic = _prefs.getBool(_prefIsMnemonicKey) ?? false;
    if (isMnemonic) {
      isWalletTypeMnemonic = isMnemonic;
      String mnemonic = _prefs.getString(_prefMnemonicKey) ?? null;
      if (mnemonic != null) {
        await setupWalletFromMnemonic(
            mnemonic); // probably load wallet from pref func is needed
      } else {
        appUserWallet = null;
      }
    } else {
      String privKey = _prefs.getString(_prefPrivKey) ?? null;
      if (privKey != null) {
        await setupWalletFromPrivKey(
            privKey); // probably load wallet from pref func is needed
      } else {
        appUserWallet = null;
      }
    }
    notifyListeners();
  }

  // pref setters
  Future<void> _setIsWalletTypeMnemonic(bool value) async {
    await _prefs.setBool(_prefIsMnemonicKey, value);
  }

  Future<void> _setPrivateKey(String value) async {
    await _prefs.setString(_prefPrivKey, value);
  }

  Future<void> _setMnemonic(String value) async {
    await _prefs.setString(_prefMnemonicKey, value);
  }

  String _getPrivateKeyFromMnemonic(String mnemonic) {
    String seed = bip39.mnemonicToSeedHex(mnemonic);
    final root = bip32.BIP32.fromSeed(HEX.decode(seed));
    final child1 = root.derivePath("m/44'/60'/0'/0/0");
    final privateKey = HEX.encode(child1.privateKey);
    return privateKey;
  }

  // setuppers :)
  Future<void> setupWalletFromPrivKey(String privKey) async {
    appUserWallet = AppUserWallet(privkey: privKey);
    // final credentials =
    //     await client.credentialsFromPrivateKey(appUserWallet.privkey);
    // final address = await credentials.extractAddress();
    final private = EthPrivateKey.fromHex(privKey);
    final address = await private.extractAddress();
    appUserWallet.pubKey = address;
    appUserWallet.balance = await client.getBalance(address);
    await _setIsWalletTypeMnemonic(false);
    await _setPrivateKey(privKey);
    notifyListeners();
  }

  Future<void> setupWalletFromMnemonic(String mnemonic) async {
    final cryptMnemonic = bip39.mnemonicToEntropy(mnemonic);
    final privateKey = _getPrivateKeyFromMnemonic(cryptMnemonic);
    appUserWallet = AppUserWallet(privkey: privateKey);
    // final credentials =
    //     await client.credentialsFromPrivateKey(appUserWallet.privkey);
    // final address = await credentials.extractAddress();
    final private = EthPrivateKey.fromHex(privateKey);
    log('privatekey from mnemonic: ' + privateKey);
    final address = await private.extractAddress();
    appUserWallet.pubKey = address;
    appUserWallet.balance = await client.getBalance(appUserWallet.pubKey);
    await _setIsWalletTypeMnemonic(true);
    await _setMnemonic(mnemonic);
    await _setPrivateKey(privateKey);
    notifyListeners();
  }

  // deleters :)
  Future<void> distroyWallet() async {
    await initPrefs();
    await _prefs.clear();
    appUserWallet = null;
    notifyListeners();
  }

  // this stream might not be needed, i leave it as an example
  // Stream<AppUserWallet> appUserWalletStream() async* {
  //   await initPrefs();
  //   String privKey = prefs.getString(prefPrivKey) ?? null;
  //   if (privKey != null) {
  //     appUserWallet = AppUserWallet(privkey: privKey);
  //   }
  //   if (appUserWallet != null) {
  //     final credentials =
  //         await client.credentialsFromPrivateKey(appUserWallet.privkey);
  //     final address = await credentials.extractAddress();
  //     appUserWallet.pubKey = address;
  //     appUserWallet.balance = await client.getBalance(address);
  //     yield appUserWallet;
  //   }
  // }
}
