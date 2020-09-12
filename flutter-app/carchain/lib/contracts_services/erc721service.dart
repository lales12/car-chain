import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';

// events
// event classes (model)
class Transfer {
  EthereumAddress from;
  EthereumAddress to;
  UintType tokenId;
  Transfer({this.from, this.to, this.tokenId});
}

class Approval {
  EthereumAddress owner;
  EthereumAddress approved;
  UintType tokenId;
  Approval({this.owner, this.approved, this.tokenId});
}

class ApprovalForAll {
  EthereumAddress owner;
  EthereumAddress theOperator;
  bool approved;
  ApprovalForAll({this.owner, this.theOperator, this.approved});
}

class ERC721 extends ChangeNotifier {
  // for now i only pass changeNotifier as an inheritance
}
