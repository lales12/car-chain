import 'package:carchain/screens/home.dart';
import 'package:carchain/screens/importwallet.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final walletManager = Provider.of<WalletManager>(context);
    if (walletManager.isWalletLoading == false) {
      if (walletManager.getAppUserWallet == null) {
        return ImportWallet();
      } else {
        return Home();
      }
    } else {
      return Loading(
        loadingMessage: '',
      );
    }
  }
}
