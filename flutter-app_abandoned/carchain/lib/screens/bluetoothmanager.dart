import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:provider/provider.dart';

class BluetoothManager extends StatefulWidget {
  @override
  _BluetoothManagerState createState() => _BluetoothManagerState();
}

class _BluetoothManagerState extends State<BluetoothManager> {
  @override
  Widget build(BuildContext context) {
    final bluetoothState = Provider.of<BluetoothState>(context);
    if (bluetoothState != null) {
      print('BluetoothManager: ' + bluetoothState.toString());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('BlueTooth Manager'),
      ),
      body: Center(
        child: Text('Bluetooth Screen'),
      ),
    );
  }
}
