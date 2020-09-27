import 'package:vehicle_chain_app/screens/home.dart';
import 'package:vehicle_chain_app/screens/importwallet.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/util/loading.dart';
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
