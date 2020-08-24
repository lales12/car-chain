import 'package:carchain/models/AppUserWallet.dart';
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
    final appUserWallet = Provider.of<AppUserWallet>(context);
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
