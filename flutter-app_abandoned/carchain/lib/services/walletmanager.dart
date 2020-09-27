import 'dart:developer';

import 'package:carchain/models/AppUserWallet.dart';
import 'package:carchain/util/shared.dart';
import 'package:flutter/material.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;

class AppNetConfig {
  String name;
  String rpcUrl;
  String wsUrl;
  String networkId;
  AppNetConfig({this.name, this.rpcUrl, this.wsUrl, this.networkId});
}

class WalletManager with ChangeNotifier {
  // wallet variables
  String _prefPrivKey = 'privKey';
  String _prefMnemonicKey = 'mnemonic';
  String _prefIsMnemonicKey = 'isMnemonic';
  String _prefWalletAccountIndexKey = 'walletIndex';

  bool isWalletTypeMnemonic = false;
  bool isWalletLoading = true;
  AppUserWallet _appUserWallet;
  int walletAccountIndex = 0;

  // network variables
  String _prefActiveNetworkKey = "activeNetwork";

  AppNetConfig activeNetwork;

  SharedPreferences _prefs;

  // final client = Web3Client(configParams.rpcUrl, Client());
  Future<Web3Client> _getClient() async {
    await _loadNetworkFromPrefs();
    return Web3Client(activeNetwork.rpcUrl, Client());
  }

  WalletManager() {
    _appUserWallet = null;
    _loadWalletFromPrefs();
    _loadNetworkFromPrefs();
  }

  Future initPrefs() async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
  }

  Future _loadWalletFromPrefs() async {
    await initPrefs();
    // get type of wallet
    bool isMnemonic = _prefs.getBool(_prefIsMnemonicKey) ?? false;
    walletAccountIndex = _prefs.getInt(_prefWalletAccountIndexKey) ?? 0;
    if (isMnemonic) {
      isWalletTypeMnemonic = isMnemonic;
      String mnemonic = _prefs.getString(_prefMnemonicKey) ?? null;
      if (mnemonic != null) {
        await setupWalletFromMnemonic(mnemonic, false);
      } else {
        _appUserWallet = null;
        isWalletLoading = false;
      }
    } else {
      String privKey = _prefs.getString(_prefPrivKey) ?? null;
      if (privKey != null) {
        await setupWalletFromPrivKey(privKey, false);
      } else {
        _appUserWallet = null;
        isWalletLoading = false;
      }
    }
    _appUserWallet != null ? log('WalletManager: done loding wallet from pref: ' + _appUserWallet.pubKey.toString()) : log('_appUserWallet is null');
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

  Future<void> _setWalletIndex(int value) async {
    await _prefs.setInt(_prefWalletAccountIndexKey, value);
  }

  // setuppers :)
  Future<void> setupWalletFromPrivKey(String privKey, [bool setup = true]) async {
    _appUserWallet = AppUserWallet(accountIndex: walletAccountIndex);
    _appUserWallet.isMnemonic = false;
    final privateKey = EthPrivateKey.fromHex(privKey);
    final address = await privateKey.extractAddress();
    _appUserWallet.privkey = privateKey;
    _appUserWallet.pubKey = address;
    Web3Client client = await _getClient();
    _appUserWallet.balance = await client.getBalance(address);
    if (setup) {
      await _setIsWalletTypeMnemonic(false);
      await _setPrivateKey(privKey);
    }
    isWalletLoading = false;
    notifyListeners();
  }

  String _getPrivateKeyFromMnemonic(String mnemonic) {
    // using bip32
    var seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/44'/60'/0'/0/" + walletAccountIndex.toString());
    final privateKey = HEX.encode(child.privateKey);
    return privateKey;
  }

  Future<void> setupWalletFromMnemonic(String mnemonic, [bool setup = true]) async {
    final privateKey = _getPrivateKeyFromMnemonic(mnemonic);
    _appUserWallet = new AppUserWallet(accountIndex: walletAccountIndex);
    _appUserWallet.isMnemonic = true;
    final private = EthPrivateKey.fromHex(privateKey);
    log('privatekey from mnemonic: ' + privateKey);
    final address = await private.extractAddress();
    _appUserWallet.privkey = private;
    _appUserWallet.pubKey = address;
    Web3Client client = await _getClient();
    _appUserWallet.balance = await client.getBalance(_appUserWallet.pubKey);
    if (setup) {
      await _setIsWalletTypeMnemonic(true);
      await _setMnemonic(mnemonic);
    }
    await _setPrivateKey(privateKey);
    isWalletLoading = false;
    notifyListeners();
  }

  Future<void> changeWalletAccountIndex(newIndex) async {
    await initPrefs();
    await _setWalletIndex(newIndex);
    await _loadWalletFromPrefs();
    notifyListeners();
  }

  AppUserWallet get getAppUserWallet => _appUserWallet;

  // deleters :)
  Future<void> distroyWallet() async {
    await initPrefs();
    await _prefs.clear();
    _appUserWallet = null;
    notifyListeners();
  }

  // network
  Future _loadNetworkFromPrefs() async {
    await initPrefs();
    String activeNetworkName = _prefs.getString(_prefActiveNetworkKey) ?? 'dev';
    activeNetwork = networkConfigs[activeNetworkName];
    notifyListeners();
  }

  // Pref Setters
  Future<void> _setAppNetworkName(String value) async {
    await _prefs.setString(_prefActiveNetworkKey, value);
  }

  // changers
  Future<void> changeAppNetwork(String netName) async {
    await initPrefs();
    await _setAppNetworkName(netName);
    await _loadNetworkFromPrefs();
    await _loadWalletFromPrefs();
  }

  // this stream might not be needed, i leave it as an example
  // Stream<AppUserWallet> appUserWalletStream() async* {
  //   await initPrefs();
  //   String privKey = prefs.getString(prefPrivKey) ?? null;
  //   if (privKey != null) {
  //     _appUserWallet = AppUserWallet(privkey: privKey);
  //   }
  //   if (_appUserWallet != null) {
  //     final credentials =
  //         await client.credentialsFromPrivateKey(_appUserWallet.privkey);
  //     final address = await credentials.extractAddress();
  //     _appUserWallet.pubKey = address;
  //     _appUserWallet.balance = await client.getBalance(address);
  //     yield _appUserWallet;
  //   }
  // }
}
