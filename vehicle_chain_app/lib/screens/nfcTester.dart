import 'dart:developer';

import 'package:ethereum_address/ethereum_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NfcTester extends StatefulWidget {
  @override
  _NfcTesterState createState() => _NfcTesterState();
}

class _NfcTesterState extends State<NfcTester> {
  static const platformMethods = const MethodChannel('carChain.com/methodsChannel');
  static const platformEvents = const EventChannel('carChain.com/getCardInfoEvent');
  static const platformSignEvents = const EventChannel('carChain.com/signEvent');

  String _isNfcAdapterEnabled = 'Unknown Nfc Status.';
  String _nfcCardPubKeyError = 'no error yet';
  String _nfcCardPubKey;
  String _nfcCardSigniture;

  Future<void> _getNfcAdapterStatus() async {
    String isNfcAdapterEnabled;
    try {
      final bool result = await platformMethods.invokeMethod('getNfcStatus');
      isNfcAdapterEnabled = 'Nfc Status: $result ';
    } on PlatformException catch (e) {
      isNfcAdapterEnabled = "Failed to get Nfc Status: '${e.message}'.";
    }

    setState(() {
      _isNfcAdapterEnabled = isNfcAdapterEnabled;
    });
  }

  Future<void> _runCardInfoStreamOnPlatform() async {
    try {
      final bool result = await platformMethods.invokeMethod('runCardInfoStream');
      setState(() {
        _nfcCardPubKey = result ? 'Please attach your KeyCard to your device.' : 'Somthing is wrong...';
      });
      result ? _listenForCardInfo() : log('somthing is wrong');
    } on PlatformException catch (e) {
      log("Failed to launch a new stream for card info: '${e.message}'.");
    }
  }

  Future<void> _runCardSignerOnPlatform(String hash) async {
    try {
      final bool result = await platformMethods.invokeMethod('runSignStream', {"hash": hash});
      setState(() {
        _nfcCardSigniture = result ? 'Please attach your KeyCard to your device to Sign.' : 'Somthing is wrong...';
      });
      result ? _listenSignedHash() : log('somthing is wrong');
    } on PlatformException catch (e) {
      log("Failed to launch a new stream for card info: '${e.message}'.");
    }
  }

  void _listenForCardInfo() {
    platformEvents.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _listenSignedHash() {
    platformSignEvents.receiveBroadcastStream().listen(_onSignEvent, onError: _onError);
  }

  void _onSignEvent(Object event) {
    log(event.toString());
    log(event.toString().length.toString());
    // log(ethereumAddressFromPublicKey(event));
    setState(() {
      _nfcCardSigniture = event.toString();
    });
  }

  void _onEvent(Object event) {
    // log(event.toString());
    // log(event.toString().length.toString());
    // log(ethereumAddressFromPublicKey(event));
    setState(() {
      _nfcCardPubKey = ethereumAddressFromPublicKey(event);
      log(_nfcCardPubKey);
    });
  }

  void _onError(Object error) {
    log(error.toString());
    setState(() {
      _nfcCardPubKeyError = error.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nfc Testing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(height: 20.0),
            RaisedButton(
              child: Text('Get NFC Status'),
              onPressed: () async {
                await _getNfcAdapterStatus();
              },
            ),
            SizedBox(height: 20.0),
            Center(
              child: Text(_isNfcAdapterEnabled),
            ),
            SizedBox(height: 20.0),
            RaisedButton(
              child: Text('Listen for Card Info'),
              onPressed: () async {
                await _runCardInfoStreamOnPlatform();
              },
            ),
            SizedBox(height: 20.0),
            Center(
              child: Text(
                _nfcCardPubKey != null ? 'Card Address: ' + _nfcCardPubKey.toString() : _nfcCardPubKeyError,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
