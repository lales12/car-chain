import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NfcTester extends StatefulWidget {
  @override
  _NfcTesterState createState() => _NfcTesterState();
}

class _NfcTesterState extends State<NfcTester> {
  static const platform = const MethodChannel('samples.flutter.dev/keycard');
  String _isNfcAdapterEnabled = 'Unknown Nfc Status Yet.';
  String _nfcApplicationInfo;

  Future<void> _getNfcAdapterStatus() async {
    String isNfcAdapterEnabled;
    try {
      final bool result = await platform.invokeMethod('getNfcStatus');
      isNfcAdapterEnabled = 'Nfc Status: $result .';
    } on PlatformException catch (e) {
      isNfcAdapterEnabled = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _isNfcAdapterEnabled = isNfcAdapterEnabled;
    });
  }

  Future<void> _getKeycardApplicationInfo() async {
    String nfcApplicationInfo;
    try {
      final String result = await platform.invokeMethod('getKeycardApplicationInfo');
      nfcApplicationInfo = result;
    } on PlatformException catch (e) {
      log(e.toString());
    }

    setState(() {
      _nfcApplicationInfo = nfcApplicationInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nfc Testing'),
      ),
      body: Column(
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
          RaisedButton(
            child: Text('Call Keycard Info'),
            onPressed: () async {
              await _getKeycardApplicationInfo();
            },
          ),
          SizedBox(height: 20.0),
          Center(
            child: Text(_nfcApplicationInfo.toString()),
          ),
        ],
      ),
    );
  }
}
