import 'package:carchain/contract_models/permissions.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PermissionsTab extends StatefulWidget {
  @override
  _PermissionsTabState createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab> {
  @override
  Widget build(BuildContext context) {
    final permissionsContract = Provider.of<PermissionContract>(context);
    if (permissionsContract.doneLoading) {
      print('permistion contract address: ' +
          permissionsContract.contractAddress.toString());
      return Container(
        child: Center(
          child: Text('Permissions Tab'),
        ),
      );
    } else {
      return Loading(
        loadingMessage: 'Loading Contract...',
      );
    }
  }
}
