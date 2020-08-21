import 'package:carchain/contract_models/permissions.dart';
import 'package:carchain/screens/tabs/hometab.dart';
import 'package:carchain/screens/tabs/permissionstab.dart';
import 'package:carchain/services/walletmanager.dart';
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
    final walletManager = Provider.of<WalletManager>(context);
    return MultiProvider(
      // we use this multi provider to provide smart contracts to all child widgets
      providers: [
        ChangeNotifierProvider<PermissionContract>(
          create: (_) => PermissionContract(walletManager.getWallet().privkey),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('Car Chain'),
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
