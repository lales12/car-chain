import 'package:vehicle_chain_app/services/appbluetoothservice.dart';
import 'package:vehicle_chain_app/services/appsettingservice.dart';
import 'package:vehicle_chain_app/wrapper.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/util/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(
          value: AppSettings(),
        ),
        ChangeNotifierProvider<WalletManager>.value(
          value: WalletManager(),
        ),
        StreamProvider<BluetoothState>.value(
          value: AppBlueToothService().getBluetoothState,
        ),
      ],
      child: MaterialApp(debugShowCheckedModeBanner: true, home: Wrapper(), theme: lightTheme),
    );
  }
}
