import 'package:carchain/services/appbluetoothservice.dart';
import 'package:carchain/services/appsettingservice.dart';
import 'package:carchain/wrapper.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/shared.dart';
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
