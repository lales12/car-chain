import 'package:carchain/screens/wrapper.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WalletManager(),
      child: MaterialApp(
        home: Wrapper(),
        theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            inputDecorationTheme:
                InputDecorationTheme(contentPadding: EdgeInsets.all(5.0))),
      ),
    );
  }
}
