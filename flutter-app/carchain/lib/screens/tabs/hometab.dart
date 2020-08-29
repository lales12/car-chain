import 'package:carchain/contracts_services/cartracker.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/cards.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final appUserWallet = Provider.of<WalletManager>(context).appUserWallet;
    final carTracker = Provider.of<CarTracker>(context);
    if (carTracker != null) {
      print('carTracker: ' + carTracker.doneLoading.toString());
      print('carTracker functions: ' +
          carTracker.contractFunctionsList.toString());
    }
    if (appUserWallet != null && appUserWallet.balance != null) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              IconCountCard(
                cardTitle: 'Balance',
                cardIcon: Icon(Icons.account_balance),
                count: appUserWallet.balance
                    .getValueInUnit(EtherUnit.ether)
                    .toStringAsFixed(4),
                subTitle: appUserWallet.balance
                        .getValueInUnit(EtherUnit.wei)
                        .toString() +
                    ' Wei',
              )
            ],
          ),
        ),
      );
    }
    return Loading();
  }
}
