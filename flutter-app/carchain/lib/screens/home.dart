import 'package:carchain/contracts_services/cartracker.dart';
import 'package:carchain/contracts_services/permissions.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/renderqr.dart';
import 'package:carchain/screens/settings.dart';
import 'package:carchain/screens/tabs/hometab.dart';
import 'package:carchain/screens/tabs/permissionstab.dart';
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
    Container(child: PermissionsTab()),
  ];
  // Tab Items
  final navItems = [
    BottomNavigationBarItem(
      label: 'Home',
      icon: Icon(Icons.home),
    ),
    BottomNavigationBarItem(
      label: 'Permisions',
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
        ChangeNotifierProvider<PermissionContract>(
          create: (_) => PermissionContract(appUserWallet.privkey),
        ),
        ChangeNotifierProvider<CarTracker>(
          create: (_) => CarTracker(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Car Chain'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Settings()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.qr_code),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RenderQr(
                      title: 'Wallet Address',
                      qrMessage: "Wallet's public address",
                      qrData: appUserWallet.pubKey.toString(),
                      subTitle: appUserWallet.pubKey.toString(),
                    ),
                  ),
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
