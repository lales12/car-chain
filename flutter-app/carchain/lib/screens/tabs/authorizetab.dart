import 'package:carchain/contracts_services/cartracker.dart';
import 'package:carchain/contracts_services/permissions.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthorizeTab extends StatefulWidget {
  @override
  _AuthorizeTabState createState() => _AuthorizeTabState();
}

class _AuthorizeTabState extends State<AuthorizeTab> {
  @override
  Widget build(BuildContext context) {
    final appUserWallet = Provider.of<WalletManager>(context).appUserWallet;
    final permissionsContract = Provider.of<PermissionContract>(context);
    final carTrackeContract = Provider.of<CarTracker>(context);

    if (permissionsContract.doneLoading && carTrackeContract.doneLoading) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [],
              )),
        ),
      );
    } else {
      return Loading();
    }
  }
}
