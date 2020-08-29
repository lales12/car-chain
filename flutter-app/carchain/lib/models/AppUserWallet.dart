import 'package:web3dart/web3dart.dart';

class AppUserWallet {
  bool isMnemonic;
  int accountIndex;
  EthPrivateKey privkey;
  EthereumAddress pubKey;
  EtherAmount balance;
  AppUserWallet({this.accountIndex});
}
