import 'package:carchain/models/AppUserWallet.dart';
import 'package:carchain/screens/wrapper.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/shared.dart';
import 'package:flutter/material.dart';
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
        StreamProvider<AppUserWallet>.value(
            value: WalletManager().appUserWalletStream())
      ],
      child: MaterialApp(home: Wrapper(), theme: lightTheme),
    );
  }
}
