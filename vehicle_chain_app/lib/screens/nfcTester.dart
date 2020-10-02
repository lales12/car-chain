import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NfcTester extends StatefulWidget {
  @override
  _NfcTesterState createState() => _NfcTesterState();
}

class _NfcTesterState extends State<NfcTester> {
  static const platformMethods = const MethodChannel('samples.flutter.dev/keycard');
  static const platformEvents = const EventChannel('samples.flutter.dev/getCardPubKeyEevent');

  String _isNfcAdapterEnabled = 'Unknown Nfc Status Yet.';
  String _nfcCardPubKeyError = 'no error yet';
  String _nfcCardPubKey;

  Future<void> _getNfcAdapterStatus() async {
    String isNfcAdapterEnabled;
    try {
      final bool result = await platformMethods.invokeMethod('getNfcStatus');
      isNfcAdapterEnabled = 'Nfc Status: $result .';
    } on PlatformException catch (e) {
      isNfcAdapterEnabled = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _isNfcAdapterEnabled = isNfcAdapterEnabled;
    });
  }

  @override
  void initState() {
    super.initState();
    platformEvents.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void _onEvent(Object event) {
    log(event.toString());
    log(event.toString().length.toString());

    setState(() {
      _nfcCardPubKey = event;
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
              child: Text('Call Nfc adapter'),
              onPressed: () async {
                await _getNfcAdapterStatus();
              },
            ),
            SizedBox(height: 20.0),
            Center(
              child: Text(_isNfcAdapterEnabled),
            ),
            SizedBox(height: 20.0),
            Center(
              child: Text(_nfcCardPubKey ?? _nfcCardPubKeyError),
            ),
          ],
        ),
      ),
    );
  }
}
