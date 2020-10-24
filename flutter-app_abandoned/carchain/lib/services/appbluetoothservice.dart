import 'dart:async';

import 'package:flutter_ble_lib/flutter_ble_lib.dart';

class AppBlueToothService {
  // states
  BleManager bleManager = new BleManager();

  // functions

  // Streams
  Stream<BluetoothState> get getBluetoothState {
    StreamController<BluetoothState> controller;

    void start() async {
      await bleManager.createClient();
      BluetoothState currentState = await bleManager.bluetoothState();
      controller.add(currentState);
      bleManager.observeBluetoothState().listen((btState) {
        controller.add(btState);
      });
    }

    void stop() {
      bleManager.destroyClient();
      controller.close();
    }

    controller = StreamController<BluetoothState>(
      onListen: start,
      onPause: stop,
      onResume: start,
      onCancel: stop,
    );

    return controller.stream;
  }
}
