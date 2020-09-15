import 'package:carchain/contracts_services/itvmanagercontractservice.dart';
import 'package:carchain/contracts_services/vehiclemanagercontractservice.dart';
import 'package:carchain/contracts_services/authorizercontractservice.dart';
import 'package:carchain/screens/accountprofile.dart';
import 'package:carchain/screens/bluetoothmanager.dart';
import 'package:carchain/screens/tabs/authorizertab.dart';
import 'package:carchain/screens/tabs/vehiclemanagertab.dart';
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
    Container(child: VehicleManagerTab()),
    Container(child: AuthorizerTab()),
  ];
  // Tab Items
  final navItems = [
    BottomNavigationBarItem(
      label: 'Home',
      icon: Icon(Icons.home),
    ),
    BottomNavigationBarItem(
      label: 'Vehicles',
      icon: Icon(Icons.car_repair),
    ),
    BottomNavigationBarItem(
      label: 'Authorize',
      icon: Icon(Icons.privacy_tip),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final walletManager = Provider.of<WalletManager>(context);
    if (walletManager == null) {
      return Loading(
        loadingMessage: '',
      );
    } else {
      // re-initialize
      AuthorizerContract authContract = AuthorizerContract(walletManager);
      CarManager vehicleManagerContract = CarManager(walletManager);
      ItvManager itvManager = ItvManager(walletManager);
      return MultiProvider(
        // we use this multi provider to provide smart contracts to all child widgets
        providers: [
          ChangeNotifierProvider<AuthorizerContract>.value(
            value: authContract,
          ),
          ChangeNotifierProvider<CarManager>.value(
            // create: (context) => vehicleManagerContract,
            value: vehicleManagerContract,
          ),
          ChangeNotifierProvider<ItvManager>.value(
            value: itvManager,
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
}
