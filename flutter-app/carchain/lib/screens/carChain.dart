import 'package:carchain/contract_models/permissions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CarChain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final permisions = Provider.of<Permissions>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Chain'),
      ),
      body: Center(
        child: Text(permisions.contractOwner.toString()),
      ),
    );
  }
}
