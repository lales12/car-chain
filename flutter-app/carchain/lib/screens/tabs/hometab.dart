import 'package:carchain/contracts_services/vehiclemanagercontractservice.dart';
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
    final carManager = Provider.of<CarManager>(context);
    if (carManager != null && carManager.doneLoading) {
      print('carManager: ' + carManager.doneLoading.toString());
      print('carManager functions: ' + carManager.contractFunctionsList.toString());

      print('tocken balance: ' + carManager.usersOwnedVehicles.toString());
    }
    if (appUserWallet != null && appUserWallet.balance != null && carManager != null && carManager.doneLoading) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              IconCountCard(
                cardTitle: 'Balance',
                cardIcon: Icon(Icons.account_balance),
                count: appUserWallet.balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(4),
                subTitle: appUserWallet.balance.getValueInUnit(EtherUnit.wei).toString() + ' Wei',
              ),
              IconCountCard(
                cardTitle: 'Vehicles',
                cardIcon: Icon(Icons.car_rental),
                count: carManager.usersOwnedVehicles.toString() ?? '0',
                subTitle: 'Total Number of Vehicles Owned',
              ),
            ],
          ),
        ),
      );
    }
    return Loading();
  }
}
