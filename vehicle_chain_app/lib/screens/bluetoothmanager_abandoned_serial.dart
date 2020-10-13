// import 'dart:developer';

// import 'package:vehicle_chain_app/services/appbluetoothservice.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:provider/provider.dart';

// class BluetoothManager extends StatefulWidget {
//   @override
//   _BluetoothManagerState createState() => _BluetoothManagerState();
// }

// class _BluetoothManagerState extends State<BluetoothManager> {
//   List<BluetoothDevice> bluetoothPairedList;

//   Future<void> _showModal(BuildContext context, BluetoothDevice device) {
//     return showModalBottomSheet<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setModalState) {
//             BluetoothConnection connection;

//             return Container(
//               height: 750,
//               child: Column(
//                 mainAxisSize: MainAxisSize.max,
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   ListTile(
//                     leading: Icon(Icons.devices),
//                     title: Text(device.name),
//                     subtitle: Text(device.address),
//                     trailing: connection != null
//                         ? connection.isConnected ?? device.isConnected
//                         : device.isConnected
//                             ? TextButton.icon(
//                                 label: Text('Disconnect'),
//                                 icon: Icon(Icons.bluetooth_disabled),
//                                 onPressed: () async {
//                                   // TO DO
//                                   connection.close();
//                                 },
//                               )
//                             : TextButton.icon(
//                                 label: Text('Connect'),
//                                 icon: Icon(Icons.bluetooth_connected),
//                                 onPressed: () {
//                                   log('connecting to: ' + device.address.toString());
//                                   BluetoothConnection.toAddress(device.address)
//                                       .then(
//                                         (BluetoothConnection connectionResult) => setModalState(
//                                           () {
//                                             connection = connectionResult;
//                                           },
//                                         ),
//                                       )
//                                       .catchError(
//                                         (onError) => log(onError.toString()),
//                                       );
//                                 },
//                               ),
//                   ),
//                   if (connection != null) ...[
//                     Text('commands'),
//                   ],
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void updateBluetoothPairedList() {
//     AppBlueToothService().getPairedDevices().then((List<BluetoothDevice> value) {
//       setState(() {
//         bluetoothPairedList = value;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bluetoothState = Provider.of<BluetoothState>(context);
//     if (bluetoothState != null) {
//       updateBluetoothPairedList();
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('BlueTooth Manager'),
//         actions: [
//           IconButton(
//             icon: bluetoothState != BluetoothState.STATE_ON
//                 ? Icon(Icons.bluetooth_disabled)
//                 : Icon(
//                     Icons.bluetooth,
//                     // color: Theme.of(context).primaryColorLight,
//                   ),
//             onPressed: () async {
//               if (bluetoothState != BluetoothState.STATE_ON) {
//                 log('turning blutooth on');
//                 bool temp = await AppBlueToothService().enableBluetooth();
//                 if (temp) {
//                   log('blutooth enabled');
//                 } else {
//                   log(temp.toString());
//                 }
//               } else {
//                 log('turning blutooth of');
//                 bool temp = await AppBlueToothService().disableBluetooth();
//                 if (temp) {
//                   log('blutooth disabled');
//                 } else {
//                   log(temp.toString());
//                 }
//               }
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.max,
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               if (bluetoothState != BluetoothState.STATE_ON) ...[
//                 Center(
//                   child: Text("The Bluetooth Adapter seems to be OFF, try turning it ON from the App Bar's Bluetooth button"),
//                 ),
//               ],
//               if (bluetoothState == BluetoothState.STATE_ON && bluetoothPairedList != null && bluetoothPairedList.length == 0) ...[
//                 Center(
//                   child: Text("It appear that you don't have any device paired, go to settings and pair with a device."),
//                 ),
//                 SizedBox(height: 20.0),
//                 RaisedButton(
//                   child: Text('Open Settings'),
//                   onPressed: () {
//                     AppBlueToothService().openSettings();
//                   },
//                 ),
//               ],
//               if (bluetoothPairedList != null) ...[
//                 ...bluetoothPairedList
//                     .map(
//                       (device) => ListTile(
//                         leading: Icon(Icons.devices_other),
//                         title: Text(device.name),
//                         subtitle: Text(device.address),
//                         trailing: device.isConnected
//                             ? Icon(
//                                 Icons.bluetooth_connected,
//                                 color: Theme.of(context).primaryColorLight,
//                               )
//                             : Icon(
//                                 Icons.bluetooth_disabled,
//                                 color: Theme.of(context).accentColor,
//                               ),
//                         onTap: () {
//                           // show buttom modal
//                           _showModal(context, device);
//                         },
//                       ),
//                     )
//                     .toList(),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
