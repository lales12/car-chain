// import 'dart:async';
// import 'dart:developer';

// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// class AppBlueToothService {
//   // instance
//   FlutterBluetoothSerial bluetoothInstance = FlutterBluetoothSerial.instance;

//   // functions
//   Future<bool> enableBluetooth() async {
//     try {
//       return await bluetoothInstance.requestEnable();
//     } catch (e) {
//       log(e);
//       return false;
//     }
//   }

//   Future<bool> disableBluetooth() async {
//     try {
//       return await bluetoothInstance.requestDisable();
//     } catch (e) {
//       log(e);
//       return false;
//     }
//   }

//   Future<List<BluetoothDevice>> getPairedDevices() async {
//     return await bluetoothInstance.getBondedDevices();
//   }

//   Future<void> openSettings() {
//     return bluetoothInstance.openSettings();
//   }

//   // Streams
//   Stream<BluetoothState> get getBluetoothState {
//     StreamController<BluetoothState> controller;

//     void start() {
//       bluetoothInstance.state.then((BluetoothState state) {
//         controller.add(state);
//       });
//       bluetoothInstance.onStateChanged().listen((BluetoothState state) {
//         controller.add(state);
//       });
//     }

//     void stop() {
//       controller.close();
//     }

//     controller = StreamController<BluetoothState>(
//       onListen: start,
//       onPause: stop,
//       onResume: start,
//       onCancel: stop,
//     );

//     return controller.stream;
//   }
// }
