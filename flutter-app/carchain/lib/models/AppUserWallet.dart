import 'package:web3dart/web3dart.dart';

class AppUserWallet {
  String privkey;
  EthereumAddress pubKey;
  EtherAmount balance;
  AppUserWallet({this.privkey});
}
