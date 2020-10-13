// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_blue/flutter_blue.dart';
// import 'package:progress_state_button/iconed_button.dart';
// import 'package:progress_state_button/progress_button.dart';
// import 'package:provider/provider.dart';

// class BlueToothManager extends StatefulWidget {
//   @override
//   _BlueToothManagerState createState() => _BlueToothManagerState();
// }

// class _BlueToothManagerState extends State<BlueToothManager> {
//   ButtonState stateBtConnectButton = ButtonState.idle;
//   @override
//   Widget build(BuildContext context) {
//     final bluetoothState = Provider.of<BluetoothState>(context);
//     final bluetoothConnectedDevices = Provider.of<List<BluetoothDevice>>(context);
//     if (bluetoothState != null && bluetoothConnectedDevices != null) {
//       print(bluetoothState.toString());
//       print(bluetoothConnectedDevices.length);
//     }
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Bluetooth Manager'),
//         actions: [
//           IconButton(
//             icon: Icon((bluetoothState == BluetoothState.on) ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.max,
//           children: [
//             StreamBuilder<List<ScanResult>>(
//               stream: FlutterBlue.instance.scanResults,
//               initialData: [],
//               builder: (c, snapshot) => Column(
//                 children: snapshot.data
//                     .map(
//                       (scanResult) => ListTile(
//                         title: Text(scanResult.device.name == '' ? 'Unknown' : scanResult.device.name),
//                         subtitle: Text(scanResult.device.id.toString()),
//                         trailing: Icon(scanResult.advertisementData.connectable ? Icons.bluetooth_searching : Icons.bluetooth_disabled),
//                         enabled: scanResult.advertisementData.connectable ? true : false,
//                         tileColor: Theme.of(context).primaryColor,
//                         onTap: () {
//                           showModalBottomSheet<void>(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return StatefulBuilder(
//                                 builder: (BuildContext context, StateSetter setModalState) {
//                                   return Container(
//                                     height: 500,
//                                     // color: Colors.amber,
//                                     child: Center(
//                                       child: Column(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: <Widget>[
//                                           Text(
//                                             (scanResult.device.name == '') ? 'Unknown' : scanResult.device.name,
//                                             style: TextStyle(color: Theme.of(context).primaryColorLight),
//                                           ),
//                                           SizedBox(height: 20.0),
//                                           Text(
//                                             scanResult.device.id.toString(),
//                                             style: TextStyle(color: Theme.of(context).primaryColorLight),
//                                           ),
//                                           SizedBox(height: 20.0),
//                                           ProgressButton.icon(
//                                             iconedButtons: {
//                                               ButtonState.idle: IconedButton(
//                                                   text: 'Connect',
//                                                   icon: Icon(Icons.bluetooth_sharp, color: Colors.white),
//                                                   color: Theme.of(context).buttonColor),
//                                               ButtonState.loading: IconedButton(text: "Loading", color: Theme.of(context).buttonColor),
//                                               ButtonState.fail: IconedButton(
//                                                   text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
//                                               ButtonState.success: IconedButton(
//                                                   text: "Success",
//                                                   icon: Icon(
//                                                     Icons.check_circle,
//                                                     color: Colors.white,
//                                                   ),
//                                                   color: Theme.of(context).buttonColor)
//                                             },
//                                             state: stateBtConnectButton,
//                                             onPressed: () async {
//                                               bool opStatus = true;
//                                               setModalState(() {
//                                                 stateBtConnectButton = ButtonState.loading;
//                                               });
//                                               await scanResult.device.connect().timeout(Duration(seconds: 10), onTimeout: () {
//                                                 opStatus = false;
//                                                 setModalState(() {
//                                                   stateBtConnectButton = ButtonState.fail;
//                                                 });
//                                                 Timer(Duration(seconds: 2), () {
//                                                   stateBtConnectButton = ButtonState.idle;
//                                                 });
//                                               }).catchError((onError) {
//                                                 opStatus = false;
//                                                 print(onError);
//                                                 setModalState(() {
//                                                   stateBtConnectButton = ButtonState.fail;
//                                                 });
//                                                 Timer(Duration(seconds: 2), () {
//                                                   stateBtConnectButton = ButtonState.idle;
//                                                 });
//                                               }).then((value) {
//                                                 print('BT connecting finished');
//                                                 if (opStatus) {
//                                                   setModalState(() {
//                                                     stateBtConnectButton = ButtonState.success;
//                                                   });
//                                                   Timer(Duration(seconds: 2), () {
//                                                     Navigator.pop(context);
//                                                   });
//                                                 }
//                                               });
//                                             },
//                                           )
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     )
//                     .toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: StreamBuilder<bool>(
//         stream: FlutterBlue.instance.isScanning,
//         initialData: false,
//         builder: (c, snapshot) {
//           if (snapshot.data) {
//             return FloatingActionButton(
//               child: Icon(Icons.stop),
//               onPressed: () => FlutterBlue.instance.stopScan(),
//               backgroundColor: Theme.of(context).accentColor,
//             );
//           } else {
//             return FloatingActionButton(
//               child: Icon(Icons.search),
//               onPressed: () => FlutterBlue.instance.startScan(
//                 allowDuplicates: false,
//                 timeout: Duration(seconds: 60),
//               ),
//             );
//           }
//         },
//       ),
//     );
//   }
// }
