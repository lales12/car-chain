import 'dart:developer';

import 'package:vehicle_chain_app/contracts_services/vehicleassetcontractservice.dart';
import 'package:vehicle_chain_app/contracts_services/vehiclemanagercontractservice.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/util/cards.dart';
import 'package:vehicle_chain_app/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int carIndex;
  final Map<String, int> vehicleStates = {'SHIPPED': 1, 'FOR_SALE': 2, 'SOLD': 3, 'REGISTERED': 4};
  @override
  void dispose() {
    super.dispose();
    setState(() {
      carIndex = null;
    });
  }

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
            setState(() {
              carIndex = null;
            });
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
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
                  count: vehicleAssetContract.usersTotalNumberOwnedVehicles.toString() ?? '??',
                  subTitle: 'Total Number of Vehicles Owned',
                ),
                Divider(thickness: 2.0, height: 40.0),
                if (vehicleAssetContract.usersTotalNumberOwnedVehicles > BigInt.zero) ...[
                  Card(
                    margin: EdgeInsets.all(5.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('List of owned vehicles.'),
                        ),
                        SizedBox(height: 20.0),
                        DropdownButtonFormField(
                          items: () {
                            List<DropdownMenuItem> dropList = new List<DropdownMenuItem>();
                            for (var i = 0; i < vehicleAssetContract.usersTotalNumberOwnedVehicles.toInt(); i++) {
                              String shortCarAddr = vehicleAssetContract.usersListOwnedVehicles[i].address.toString().substring(0, 12) + '...';
                              dropList.add(DropdownMenuItem(value: i, child: Text('Vehicle No.' + (i + 1).toString() + ', ' + shortCarAddr)));
                            }
                            return dropList;
                          }(),
                          decoration: InputDecoration().copyWith(hintText: 'Car Index'),
                          onChanged: (val) {
                            setState(() {
                              carIndex = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(thickness: 2.0, height: 40.0),
                  StreamBuilder(
                    stream: vehicleAssetContract.transferEventListStream,
                    builder: (context, AsyncSnapshot<List<TransferEvent>> snapShot) {
                      if (snapShot.hasError) {
                        return Text('error: ' + snapShot.toString());
                      } else if (snapShot.connectionState == ConnectionState.waiting) {
                        return Text('Transfer Vehicle Event waiting...');
                      } else {
                        if (carIndex != null && snapShot.data.length > 0) {
                          OwnedVehicle selectedVehicle = vehicleAssetContract.usersListOwnedVehicles[carIndex];
                          snapShot.data.removeWhere((element) => element.tokenId != selectedVehicle.id);
                          if (snapShot.data.length > 0) {
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Center(
                                  child: Text(
                                    'Vehicle Transfer History',
                                    style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                                  ),
                                ),
                                ...snapShot.data.map(
                                  (event) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.all(5.0),
                                      isThreeLine: true,
                                      title: SelectableText('Vehicle Id: ' + event.tokenId.toString()),
                                      subtitle: SelectableText('From: ' + event.from.toString() + '\n' + 'To: ' + event.to.toString()),
                                    );
                                  },
                                ).toList(),
                              ],
                            );
                          } else {
                            return Text('No history yet.');
                          }
                        } else {
                          return Text('No Vehicle is selected.');
                        }
                      }
                    },
                  ),
                  Divider(thickness: 2.0, height: 40.0),
                  StreamBuilder(
                    stream: vehicleManagerContract.carStateUpdatedEventListStream,
                    builder: (context, AsyncSnapshot<List<CarStateUpdatedEvent>> snapShot) {
                      if (snapShot.hasError) {
                        return Text('error: ' + snapShot.toString());
                      } else if (snapShot.connectionState == ConnectionState.waiting) {
                        return Text('Transfer Vehicle Event waiting...');
                      } else {
                        if (carIndex != null && snapShot.data.length > 0) {
                          OwnedVehicle selectedVehicle = vehicleAssetContract.usersListOwnedVehicles[carIndex];
                          snapShot.data.removeWhere((element) => element.carAddress != selectedVehicle.address);
                          if (snapShot.data.length > 0) {
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Center(
                                  child: Text(
                                    'Vehicle Update History',
                                    style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                                  ),
                                ),
                                ...snapShot.data.map(
                                  (event) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.all(5.0),
                                      isThreeLine: true,
                                      title: SelectableText('Vehicle address: ' + event.carAddress.toString()),
                                      subtitle: SelectableText('Updated to State: ' +
                                          vehicleStates.keys.firstWhere((k) => vehicleStates[k] == event.state.toInt() + 1, orElse: () => 'Not Set Yet') +
                                          '\n' +
                                          'Update at block: ' +
                                          event.blockNumber.toString()),
                                    );
                                  },
                                ).toList(),
                              ],
                            );
                          } else {
                            return Text('No history yet.');
                          }
                        } else {
                          return Text('No Vehicle is selected.');
                        }
                      }
                    },
                  ),
                ],
                if (vehicleAssetContract.usersTotalNumberOwnedVehicles == BigInt.zero) ...[
                  Center(
                    child: Text(' Welcome to CarChain '),
                  )
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Loading();
  }
}
