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
  @override
  Widget build(BuildContext context) {
    final walletManager = Provider.of<WalletManager>(context);
    if (isLoading) {
      return Loading(loadingMessage: loadingMessage);
    }
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
