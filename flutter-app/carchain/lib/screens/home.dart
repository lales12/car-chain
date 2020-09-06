import 'package:carchain/contracts_services/carmanagercontractservice.dart';
import 'package:carchain/contracts_services/authorizercontractservice.dart';
import 'package:carchain/screens/accountprofile.dart';
import 'package:carchain/screens/bluetoothmanager.dart';
import 'package:carchain/screens/tabs/authorizertab.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/screens/settings.dart';
import 'package:carchain/screens/tabs/hometab.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  // tabs
  final tabs = [
    Container(child: HomeTab()),
    Container(child: AuthorizerTab()),
  ];
  // Tab Items
  final navItems = [
    BottomNavigationBarItem(
      label: 'Home',
      icon: Icon(Icons.home),
    ),
    BottomNavigationBarItem(
      label: 'Authorize',
      icon: Icon(Icons.privacy_tip),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appUserWallet = Provider.of<WalletManager>(context).appUserWallet;
    if (appUserWallet == null) {
      return Loading(
        loadingMessage: '',
      );
    }
    return MultiProvider(
      // we use this multi provider to provide smart contracts to all child widgets
      providers: [
        ChangeNotifierProvider<AuthorizerContract>(
          create: (_) => AuthorizerContract(appUserWallet.privkey),
        ),
        ChangeNotifierProvider<CarManager>(
          create: (_) => CarManager(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Car Chain'),
          actions: [
            IconButton(
              icon: Icon(Icons.bluetooth),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BluetoothManager(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountProfile(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          items: navItems,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
        ),
        body: tabs[selectedIndex],
      ),
    );
  }
}
