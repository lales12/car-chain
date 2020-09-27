import 'package:carchain/contracts_services/vehicleassetcontractservice.dart';
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
    final appUserWallet = Provider.of<WalletManager>(context).getAppUserWallet;
    final vehicleManagerContract = Provider.of<CarManager>(context, listen: true);
    final vehicleAssetContract = Provider.of<VehicleAssetContractService>(context);
    if (appUserWallet != null &&
        appUserWallet.balance != null &&
        vehicleManagerContract != null &&
        vehicleManagerContract.doneLoading &&
        vehicleAssetContract.doneLoading) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await vehicleAssetContract.updateUserOwnedVehicles();
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height,
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
                    count: vehicleAssetContract.usersOwnedVehicles.toString() ?? '??',
                    subTitle: 'Total Number of Vehicles Owned',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Loading();
  }
}
