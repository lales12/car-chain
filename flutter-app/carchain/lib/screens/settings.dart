import 'dart:developer';

import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool isLoading = false;
  String loadingMessage = 'Loading...';
  String networkDropdownValue = 'dev';
  @override
  Widget build(BuildContext context) {
    final walletManager = Provider.of<WalletManager>(context);
    if (isLoading) {
      return Loading(loadingMessage: loadingMessage);
    }
    networkDropdownValue = walletManager.activeNetwork.name;
    log('networkDropdownValue = ' + networkDropdownValue);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ListTile(
                    leading: Icon(Icons.network_wifi),
                    title: Text('Network'),
                    subtitle: Text("Change App's Network."),
                    trailing: DropdownButton<String>(
                      value: networkDropdownValue,
                      style: TextStyle(color: Theme.of(context).primaryColorLight),
                      onChanged: (String newValue) {
                        print('network is setting to: ' + newValue);
                        walletManager.changeAppNetwork(newValue);
                      },
                      items: walletManager.networkConfigs.entries.map<DropdownMenuItem<String>>((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.key),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ListTile(
                    leading: Icon(Icons.remove_circle),
                    title: Text('Remove Wallet'),
                    subtitle: Text('Reamove Your Wallet From The App.'),
                    trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                            loadingMessage = '';
                          });
                          await walletManager.distroyWallet();
                          Navigator.pop(context);
                        }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
