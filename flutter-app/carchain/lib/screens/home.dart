import 'package:carchain/contracts_services/permissions.dart';
import 'package:carchain/models/AppUserWallet.dart';
import 'package:carchain/screens/settings.dart';
import 'package:carchain/screens/tabs/hometab.dart';
import 'package:carchain/screens/tabs/permissionstab.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

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
    final appUserWallet = Provider.of<AppUserWallet>(context);
    return MultiProvider(
      // we use this multi provider to provide smart contracts to all child widgets
      providers: [
        ChangeNotifierProvider<PermissionContract>(
          create: (_) => PermissionContract(appUserWallet.privkey),
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
            )
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
