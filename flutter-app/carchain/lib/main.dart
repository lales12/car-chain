import 'package:carchain/services/appbluetoothservice.dart';
import 'package:carchain/wrapper.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletManager>(
          create: (_) => WalletManager(),
        ),
        StreamProvider<BluetoothState>.value(
          // gives u the state of device's bluetooth => if it is on/off
          value: AppBlueToothService().getBluetoothState,
        ),
        // StreamProvider<BluetoothState>.value(
        //   // gives u the state of device's bluetooth => if it is on/off
        //   value: FlutterBlue.instance.state,
        // ),
        // StreamProvider<List<BluetoothDevice>>.value(
        //   value: FlutterBlue.instance.connectedDevices.asStream(),
        // ),
      ],
      child: MaterialApp(debugShowCheckedModeBanner: true, home: Wrapper(), theme: lightTheme),
    );
  }
}
