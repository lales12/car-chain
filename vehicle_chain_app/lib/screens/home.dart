import 'package:vehicle_chain_app/contracts_services/itvmanagercontractservice.dart';
import 'package:vehicle_chain_app/contracts_services/test.dart';
import 'package:vehicle_chain_app/contracts_services/vehicleassetcontractservice.dart';
import 'package:vehicle_chain_app/contracts_services/vehiclemanagercontractservice.dart';
import 'package:vehicle_chain_app/contracts_services/authorizercontractservice.dart';
import 'package:vehicle_chain_app/screens/accountprofile.dart';
import 'package:vehicle_chain_app/screens/nfcTester.dart';
// import 'package:vehicle_chain_app/screens/bluetoothmanager.dart';
// import 'package:vehicle_chain_app/screens/nfcmanager.dart';
import 'package:vehicle_chain_app/screens/tabs/authorizertab.dart';
import 'package:vehicle_chain_app/screens/tabs/itvtab.dart';
import 'package:vehicle_chain_app/screens/tabs/vehiclemanagertab.dart';
import 'package:vehicle_chain_app/services/appsettingservice.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/screens/settings.dart';
import 'package:vehicle_chain_app/screens/tabs/hometab.dart';
import 'package:vehicle_chain_app/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final walletManager = Provider.of<WalletManager>(context);
    final appSetting = Provider.of<AppSettings>(context);
    if (walletManager == null && appSetting.activeAppRole != null) {
      return Loading(
        loadingMessage: '',
      );
    } else {
      // tabs
      final tabs = [
        Container(child: HomeTab()),
        Container(child: VehicleManagerTab()),
        if (['itv', 'admin'].contains(appSetting.activeAppRole.key)) ...[
          Container(child: ItvTab()),
        ],
        if (!['user'].contains(appSetting.activeAppRole.key)) ...[
          Container(child: AuthorizerTab()),
        ],
      ];
      // Tab Items
      final navItems = [
        BottomNavigationBarItem(
          label: 'Home',
          icon: Icon(Icons.home),
        ),
        BottomNavigationBarItem(
          label: 'Vehicles',
          icon: Icon(Icons.car_rental),
        ),
        if (['itv', 'admin'].contains(appSetting.activeAppRole.key)) ...[
          BottomNavigationBarItem(
            label: 'ITV',
            icon: Icon(Icons.car_repair),
          ),
        ],
        if (!['user'].contains(appSetting.activeAppRole.key)) ...[
          BottomNavigationBarItem(
            label: 'Authorize',
            icon: Icon(Icons.privacy_tip),
          ),
        ],
      ];

      // re-initialize
      AuthorizerContract authContract = AuthorizerContract(walletManager);
      CarManager vehicleManagerContract = CarManager(walletManager);
      ItvManager itvManager = ItvManager(walletManager);
      TestContract testContract = TestContract(walletManager);
      VehicleAssetContractService vehicleAsset = VehicleAssetContractService(walletManager);
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
          ChangeNotifierProvider<VehicleAssetContractService>.value(
            value: vehicleAsset,
          ),
          ChangeNotifierProvider<TestContract>.value(
            // create: (context) => vehicleManagerContract,
            value: testContract,
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text('Car Chain'),
            actions: [
              IconButton(
                icon: Icon(Icons.nfc),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NfcTester(),
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
            type: BottomNavigationBarType.fixed,
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
