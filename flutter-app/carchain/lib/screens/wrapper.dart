import 'package:carchain/screens/home.dart';
import 'package:carchain/screens/importwallet.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final walletManager = Provider.of<WalletManager>(context);
    if (walletManager.appUserWallet == null) {
      return ImportWallet();
    } else {
      return Home();
    }
  }
}
