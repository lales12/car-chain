import 'package:web3dart/credentials.dart';

class OwnedVehicle {
  int index;
  BigInt id;
  EthereumAddress address;
  BigInt vehicleSate;
  BigInt vehicleType;
  String licensePlate;
  OwnedVehicle({this.index, this.id, this.address});
}
