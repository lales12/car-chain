// i am not sure i will need this service class

import 'package:flutter_blue/flutter_blue.dart';

class AppBluetoothService {
  Stream<List<BluetoothDevice>> get connectedDeviced {
    return Stream.periodic(Duration(seconds: 2)).asyncMap((_) => FlutterBlue.instance.connectedDevices);
  }
}
