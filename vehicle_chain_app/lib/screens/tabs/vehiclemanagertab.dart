import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:ethereum_address/ethereum_address.dart';
import 'package:hex/hex.dart';
import 'package:tweetnacl/tweetnacl.dart';
import 'package:vehicle_chain_app/contracts_services/test.dart';
import 'package:vehicle_chain_app/contracts_services/vehicleassetcontractservice.dart';
import 'package:vehicle_chain_app/contracts_services/vehiclemanagercontractservice.dart';
import 'package:vehicle_chain_app/services/appsettingservice.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

import 'package:flutter/services.dart';

class Item {
  Item({this.name, this.shortDiscribe, this.isExpanded = false});

  String name;
  String shortDiscribe;
  bool isExpanded;
}

class VehicleManagerTab extends StatefulWidget {
  @override
  _VehicleManagerTabState createState() => _VehicleManagerTabState();
}

class _VehicleManagerTabState extends State<VehicleManagerTab> {
  // nfc
  static const platformMethods = const MethodChannel('carChain.com/methodsChannel');
  static const platformEvents = const EventChannel('carChain.com/getCardInfoEvent');
  static const platformSignEvents = const EventChannel('carChain.com/signEvent');

  String _isNfcAdapterEnabled = 'Unknown Nfc Status.';
  String _nfcCardPubKeyError = 'no error yet';
  String _nfcCardPubKey;
  String _nfcCardSigniture;
  dynamic _nfcCardSignitureList;

  Future<void> _getNfcAdapterStatus() async {
    String isNfcAdapterEnabled;
    try {
      final bool result = await platformMethods.invokeMethod('getNfcStatus');
      isNfcAdapterEnabled = 'Nfc Status: $result ';
    } on PlatformException catch (e) {
      isNfcAdapterEnabled = "Failed to get Nfc Status: '${e.message}'.";
    }

    setState(() {
      _isNfcAdapterEnabled = isNfcAdapterEnabled;
    });
  }

  Future<void> _runCardInfoStreamOnPlatform() async {
    try {
      final bool result = await platformMethods.invokeMethod('runCardInfoStream');
      setState(() {
        _nfcCardPubKey = result ? 'Please attach your KeyCard to your device.' : 'Somthing is wrong...';
      });
      result ? _listenForCardInfo() : log('somthing is wrong');
    } on PlatformException catch (e) {
      log("Failed to launch a new stream for card info: '${e.message}'.");
    }
  }

  Future<bool> _runCardSignerOnPlatform(Uint8List hash) async {
    try {
      final bool result = await platformMethods.invokeMethod('runSignStream', {"hash": hash});
      setState(() {
        _nfcCardSigniture = result ? 'Please attach your KeyCard to your device to Sign.' : 'Somthing is wrong...';
      });
      result ? _listenSignedHash() : log('somthing is wrong');
      return true;
    } on PlatformException catch (e) {
      log("Failed to launch a new stream for card info: '${e.message}'.");
      return false;
    }
  }

  void _listenForCardInfo() {
    platformEvents.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  StreamSubscription signitureSubscription;

  void _listenSignedHash() {
    signitureSubscription = platformSignEvents.receiveBroadcastStream().listen(_onSignEvent, onError: _onError);
  }

  @override
  void dispose() {
    log('vehicleManager Tab dispose');
    super.dispose();
    if (signitureSubscription != null) {
      signitureSubscription.cancel();
    }
  }

  void _onSignEvent(Object event) {
    log(event.toString());
    log(event.toString().length.toString());
    // log(ethereumAddressFromPublicKey(event));
    setState(() {
      _nfcCardSigniture = event.toString();
      _nfcCardSignitureList = json.decode(event);
      stateNFCButton = ButtonState.success;
      Timer(Duration(seconds: 4), () {
        stateNFCButton = ButtonState.idle;
      });
    });
  }

  void _onEvent(Object event) {
    // log(event.toString());
    // log(event.toString().length.toString());
    // log(ethereumAddressFromPublicKey(event));
    setState(() {
      _nfcCardPubKey = ethereumAddressFromPublicKey(event);
    });
  }

  void _onError(Object error) {
    log(error.toString());
    setState(() {
      _nfcCardPubKeyError = error.toString();
    });
  }
  ////////////////////////////////////////////////

  final _formKeyAdd = GlobalKey<FormState>();
  final _formKeyUpdate = GlobalKey<FormState>();
  final _formKeyGet = GlobalKey<FormState>();
  final _formKeyTransfer = GlobalKey<FormState>();
  final Map<String, int> vehicleStates = {'SHIPPED': 1, 'FOR_SALE': 2, 'PROCESSING_SALE': 3, 'SOLD': 4, 'PROCESSING_REGISTER': 5, 'REGISTERED': 6};
  final Map<String, int> vehicleTypes = {'TWO_WHEEL': 1, 'THREE_WHEEL': 2, 'FOUR_WHEEL': 3, 'HEAVY': 4, 'AGRICULTURE': 5, 'SERVICE': 6};
  // input for function add Vehicle
  String vehicleVIN;
  String licensePlate;
  int vehicleType;
  // input for get car function
  int tockenIndex;
  // input update car state
  BigInt inputVehicleTockenId;
  int vehicleState;
  // input transfer vehicle
  String toAddress;

  ButtonState stateCallSmartContractFunctionButton = ButtonState.idle;
  ButtonState stateNFCButton = ButtonState.idle;

  List<Item> _data = [
    Item(
      name: 'Create Vehicle',
      shortDiscribe: 'Create a new vehicle on the blockchain. \nPlease make sure you have proximity to the \nAwsome Car Card.',
      isExpanded: false,
    ),
    Item(
      name: 'Update State',
      shortDiscribe: 'Update the status of a vehicle on the blockchain.',
      isExpanded: false,
    ),
    Item(
      name: 'Get Status',
      shortDiscribe: 'Read the Status of a Vehicle',
      isExpanded: false,
    ),
    Item(
      name: 'Transfer Vehicle',
      shortDiscribe: 'Transfer the ownership of your vehicle to another address',
      isExpanded: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // final testContract = Provider.of<TestContract>(context);
    final vehicleManagerContract = Provider.of<CarManager>(context);
    final appUserWallet = Provider.of<WalletManager>(context).getAppUserWallet;
    final vehicleAssetContractService = Provider.of<VehicleAssetContractService>(context);
    final appSetting = Provider.of<AppSettings>(context);
    if (appUserWallet != null && vehicleManagerContract.doneLoading && vehicleAssetContractService.usersOwnedVehicles != null && appSetting != null) {
      //logs
      print('vehicleManagerTab Contract address: ' + vehicleManagerContract.contractAddress.toString());
      print('vehicleManagerTab Contract User address: ' + vehicleManagerContract.userAddress.toString());

      if (_nfcCardSignitureList != null) {
        log('card address: ' + ethereumAddressFromPublicKey(hexToBytes(_nfcCardSignitureList['pubkey'])));
        log('msg hash: ' + _nfcCardSignitureList['hash']);
        MsgSignature sig = MsgSignature(
            BigInt.parse('0x' + _nfcCardSignitureList['r']), BigInt.parse('0x' + _nfcCardSignitureList['s']), int.parse(_nfcCardSignitureList['v']) + 27);
        Uint8List recovered = ecRecover(hexToBytes(_nfcCardSignitureList['hash']), sig);
        log('recovered: ' + bytesToHex(recovered));
        log('signer address: ' + ethereumAddressFromPublicKey(hexToBytes('0x04' + bytesToHex(recovered))));
      }

      return Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  child: ExpansionPanelList(
                    expandedHeaderPadding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    expansionCallback: (int index, bool isExpanded) {
                      _data.forEach((item) {
                        setState(() {
                          item.isExpanded = false;
                        });
                      });
                      if (!['manufacturer', 'concessionaire', 'admin'].contains(appSetting.activeAppRole.key)) {
                        index = index + 2;
                      }
                      setState(() {
                        _data[index].isExpanded = !isExpanded;
                      });
                    },
                    children: [
                      if (['manufacturer', 'concessionaire', 'admin'].contains(appSetting.activeAppRole.key)) ...[
                        ExpansionPanel(
                          isExpanded: _data[0].isExpanded,
                          canTapOnHeader: true,
                          headerBuilder: (BuildContext context, bool isExpanded) {
                            return ListTile(
                              title: Text(_data[0].name),
                            );
                          },
                          body: Form(
                            key: _formKeyAdd,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  SizedBox(height: 20.0),
                                  Text(
                                    _data[0].shortDiscribe,
                                  ),
                                  SizedBox(height: 20.0),
                                  TextFormField(
                                    initialValue: licensePlate,
                                    decoration: InputDecoration().copyWith(hintText: 'Vehicle VIN Id'),
                                    validator: (val) => val.isEmpty ? 'Enter a valid Vehicle VIN Id' : null,
                                    onChanged: (val) {
                                      vehicleVIN = val;
                                    },
                                  ),
                                  // TextFormField(
                                  //   initialValue: licensePlate,
                                  //   decoration: InputDecoration().copyWith(hintText: 'License Plate'),
                                  //   validator: (val) => val.isEmpty ? 'Enter a valid License Plate' : null,
                                  //   onChanged: (val) {
                                  //     licensePlate = val;
                                  //   },
                                  // ),
                                  DropdownButtonFormField(
                                    items: () {
                                      List<DropdownMenuItem> tempList = new List<DropdownMenuItem>();
                                      vehicleTypes.forEach((key, value) {
                                        // print('add vehicle key: ' + key + 'add vehicle value: ' + value.toString());
                                        tempList.add(DropdownMenuItem(value: value, child: Text(key)));
                                      });
                                      return tempList;
                                    }(),
                                    decoration: InputDecoration().copyWith(hintText: 'Vehicle Type'),
                                    onChanged: (val) => vehicleType = val,
                                  ),
                                  SizedBox(height: 20.0),
                                  Text(_nfcCardSigniture != null ? 'Car Signiture: ' + _nfcCardSignitureList.toString() : ''),
                                  // if (_nfcCardSignitureList != null) ...[
                                  //   Text(MsgSignature(BigInt.parse('0x' + _nfcCardSignitureList['r']), BigInt.parse('0x' + _nfcCardSignitureList['s']),
                                  //           int.parse(_nfcCardSignitureList['v']))
                                  //       .toString())
                                  // ],

                                  SizedBox(height: 20.0),
                                  new ProgressButton.icon(
                                    iconedButtons: {
                                      ButtonState.idle: IconedButton(
                                          text: 'Get Car Signiture', icon: Icon(Icons.credit_card, color: Colors.white), color: Theme.of(context).buttonColor),
                                      ButtonState.loading: IconedButton(text: "Changing", color: Theme.of(context).buttonColor),
                                      ButtonState.fail:
                                          IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                                      ButtonState.success: IconedButton(
                                          text: "Success",
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                          color: Theme.of(context).buttonColor)
                                    },
                                    state: stateNFCButton,
                                    onPressed: () async {
                                      if (_formKeyAdd.currentState.validate()) {
                                        print('button pressed: Get Car Signiture');
                                        print(vehicleType);
                                        print(vehicleVIN);
                                        setState(() {
                                          stateNFCButton = ButtonState.loading;
                                        });
                                        try {
                                          Uint8List vinHash = keccak256(Uint8List.fromList(vehicleVIN.codeUnits));
                                          // log('hash of vin in flutter: ' + vinHash.toString());
                                          log('hash of vin in hex: ' + bytesToHex(vinHash));

                                          await _runCardSignerOnPlatform(vinHash);

                                          print('done NFC signing: ' + _nfcCardSignitureList.toString());
                                        } catch (e) {
                                          final snackBar = SnackBar(
                                            duration: Duration(seconds: 10),
                                            content: Text('error: ' + e.toString()),
                                            action: SnackBarAction(
                                              textColor: Theme.of(context).buttonColor,
                                              label: 'OK',
                                              onPressed: () {
                                                // Some code to undo the change.
                                              },
                                            ),
                                          );
                                          Scaffold.of(context).showSnackBar(snackBar);
                                          setState(() {
                                            stateNFCButton = ButtonState.fail;
                                          });
                                          // Timer(Duration(seconds: 3), () {
                                          //   setState(() {
                                          //     stateNFCButton = ButtonState.idle;
                                          //   });
                                          // });
                                        }
                                      } else {
                                        setState(() {
                                          stateNFCButton = ButtonState.idle;
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(height: 20.0),
                                  new ProgressButton.icon(
                                    iconedButtons: {
                                      ButtonState.idle:
                                          IconedButton(text: _data[0].name, icon: Icon(Icons.add, color: Colors.white), color: Theme.of(context).buttonColor),
                                      ButtonState.loading: IconedButton(text: "Changing", color: Theme.of(context).buttonColor),
                                      ButtonState.fail:
                                          IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                                      ButtonState.success: IconedButton(
                                          text: "Success",
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                          color: Theme.of(context).buttonColor)
                                    },
                                    state: stateCallSmartContractFunctionButton,
                                    onPressed: () async {
                                      if (_formKeyAdd.currentState.validate() && _nfcCardSigniture != null) {
                                        print('button pressed: ' + _data[0].name);
                                        // print(licensePlate);
                                        print(vehicleType);
                                        print(vehicleVIN);
                                        log('signiture object');
                                        // log(_nfcCardSignitureList.toString());
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.loading;
                                        });
                                        try {
                                          Uint8List vinHash = keccak256(Uint8List.fromList(vehicleVIN.codeUnits));
                                          Uint8List r = hexToBytes(_nfcCardSignitureList['r']);
                                          Uint8List s = hexToBytes(_nfcCardSignitureList['s']);
                                          BigInt v = BigInt.from(int.parse(_nfcCardSignitureList['v']) + 27);
                                          int vInt = int.parse(_nfcCardSignitureList['v']) + 27;
                                          List<int> rsv = [...r, ...s, vInt];
                                          Uint8List signiture = Uint8List.fromList(rsv);

                                          log('vin has to send: 0x' + bytesToHex(vinHash));
                                          // String result = await vehicleManagerContract.createCarRaw(vinHash, v, r, s, BigInt.parse(vehicleType.toString()));
                                          String result = await vehicleManagerContract.createCar(vinHash, signiture, BigInt.parse(vehicleType.toString()));
                                          // EthereumAddress result = await vehicleManagerContract.getAddress(vinHash, v, r, s);
                                          log('result: ' + result.toString());
                                          if (result != null) {
                                            Timer(Duration(seconds: 2), () {
                                              setState(() {
                                                stateCallSmartContractFunctionButton = ButtonState.success;
                                              });
                                              Timer(Duration(seconds: 2), () {
                                                setState(() {
                                                  stateCallSmartContractFunctionButton = ButtonState.idle;
                                                });
                                              });
                                            });
                                          }
                                          print('done call tx: ' + result.toString());
                                        } catch (e) {
                                          log(e.toString());
                                          final snackBar = SnackBar(
                                            duration: Duration(seconds: 10),
                                            content: Text('error create car button: ' + e.toString()),
                                            action: SnackBarAction(
                                              textColor: Theme.of(context).buttonColor,
                                              label: 'OK',
                                              onPressed: () {
                                                // Some code to undo the change.
                                              },
                                            ),
                                          );
                                          Scaffold.of(context).showSnackBar(snackBar);
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.fail;
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              stateCallSmartContractFunctionButton = ButtonState.idle;
                                            });
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.idle;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ExpansionPanel(
                          isExpanded: _data[1].isExpanded,
                          canTapOnHeader: true,
                          headerBuilder: (BuildContext context, bool isExpanded) {
                            return ListTile(
                              title: Text(_data[1].name),
                            );
                          },
                          body: Form(
                            key: _formKeyUpdate,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  SizedBox(height: 20.0),
                                  Text(
                                    _data[1].shortDiscribe,
                                  ),
                                  SizedBox(height: 20.0),
                                  new TextFormField(
                                    decoration: InputDecoration().copyWith(hintText: 'Vehicle Id'),
                                    validator: (val) => val.isEmpty ? 'Enter a valid Vehicle Id' : null,
                                    onChanged: (val) {
                                      inputVehicleTockenId = BigInt.parse(val);
                                    },
                                  ),
                                  SizedBox(height: 20.0),
                                  DropdownButtonFormField(
                                    items: () {
                                      List<DropdownMenuItem> tempList = new List<DropdownMenuItem>();
                                      vehicleStates.forEach((key, value) {
                                        // print('add vehicle key: ' + key + 'add vehicle value: ' + value.toString());
                                        tempList.add(DropdownMenuItem(value: value, child: Text(key)));
                                      });
                                      return tempList;
                                    }(),
                                    decoration: InputDecoration().copyWith(hintText: 'Vehicle Sate'),
                                    onChanged: (val) => vehicleState = val,
                                  ),
                                  SizedBox(height: 20.0),
                                  new ProgressButton.icon(
                                    iconedButtons: {
                                      ButtonState.idle: IconedButton(
                                          text: _data[1].name, icon: Icon(Icons.update, color: Colors.white), color: Theme.of(context).buttonColor),
                                      ButtonState.loading: IconedButton(text: "Changing", color: Theme.of(context).buttonColor),
                                      ButtonState.fail:
                                          IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                                      ButtonState.success: IconedButton(
                                          text: "Success",
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                          color: Theme.of(context).buttonColor)
                                    },
                                    state: stateCallSmartContractFunctionButton,
                                    onPressed: () async {
                                      if (_formKeyUpdate.currentState.validate()) {
                                        print('button pressed: ' + _data[1].name);
                                        print(inputVehicleTockenId);
                                        print(vehicleState);
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.loading;
                                        });
                                        try {
                                          String result = null;
                                          // await vehicleManagerContract.updateCarState(inputVehicleTockenId, BigInt.parse(vehicleState.toString()));
                                          if (result != null) {
                                            Timer(Duration(seconds: 2), () {
                                              setState(() {
                                                stateCallSmartContractFunctionButton = ButtonState.success;
                                              });
                                              Timer(Duration(seconds: 2), () {
                                                setState(() {
                                                  stateCallSmartContractFunctionButton = ButtonState.idle;
                                                });
                                              });
                                            });
                                          }
                                          print('done call tx: ' + result);
                                        } catch (e) {
                                          final snackBar = SnackBar(
                                            duration: Duration(seconds: 10),
                                            content: Text('error: ' + e.toString()),
                                            action: SnackBarAction(
                                              textColor: Theme.of(context).buttonColor,
                                              label: 'OK',
                                              onPressed: () {
                                                // Some code to undo the change.
                                              },
                                            ),
                                          );
                                          Scaffold.of(context).showSnackBar(snackBar);
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.fail;
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              stateCallSmartContractFunctionButton = ButtonState.idle;
                                            });
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.idle;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      ExpansionPanel(
                        isExpanded: _data[2].isExpanded,
                        canTapOnHeader: true,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(_data[2].name),
                          );
                        },
                        body: Form(
                          key: _formKeyGet,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Text(
                                  _data[2].shortDiscribe,
                                ),
                                SizedBox(height: 20.0),
                                DropdownButtonFormField(
                                  items: () {
                                    List<DropdownMenuItem> dropList = new List<DropdownMenuItem>();
                                    for (var i = 0; i < vehicleAssetContractService.usersOwnedVehicles.toInt(); i++) {
                                      dropList.add(DropdownMenuItem(value: i, child: Text('Vehicle No.' + (i + 1).toString())));
                                    }
                                    return dropList;
                                  }(),
                                  decoration: InputDecoration().copyWith(hintText: 'Car Index'),
                                  onChanged: (val) => tockenIndex = val,
                                ),
                                SizedBox(height: 20.0),
                                new ProgressButton.icon(
                                  iconedButtons: {
                                    ButtonState.idle: IconedButton(
                                        text: _data[2].name, icon: Icon(Icons.car_rental, color: Colors.white), color: Theme.of(context).buttonColor),
                                    ButtonState.loading: IconedButton(text: "Loading", color: Theme.of(context).buttonColor),
                                    ButtonState.fail:
                                        IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                                    ButtonState.success: IconedButton(
                                        text: "Success",
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        color: Theme.of(context).buttonColor)
                                  },
                                  state: stateCallSmartContractFunctionButton,
                                  onPressed: () async {
                                    if (_formKeyGet.currentState.validate()) {
                                      print('button pressed: ' + _data[2].name);
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.loading;
                                      });
                                      try {
                                        BigInt tokenId = await vehicleAssetContractService.getTockenIdByIndex(BigInt.parse(tockenIndex.toString()));
                                        Car result = null; //await vehicleManagerContract.getCar(tokenId);
                                        if (result != null) {
                                          final snackBar = SnackBar(
                                            duration: Duration(seconds: 30),
                                            content: Text('Your Vehicle \nid: ' +
                                                result.address.toString() +
                                                '\nLicense Plate: ' +
                                                result.licensePlate +
                                                '\nCar Type: ' +
                                                vehicleTypes.keys.firstWhere((k) => vehicleTypes[k] == result.carType.toInt(), orElse: () => null) +
                                                '\nCar State: ' +
                                                vehicleStates.keys.firstWhere((k) => vehicleStates[k] == result.carState.toInt(), orElse: () => null)),
                                            action: SnackBarAction(
                                              textColor: Theme.of(context).buttonColor,
                                              label: 'OK',
                                              onPressed: () {
                                                // Some code to undo the change.
                                              },
                                            ),
                                          );
                                          // Find the Scaffold in the widget tree and use
                                          // it to show a SnackBar.
                                          Scaffold.of(context).showSnackBar(snackBar);

                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.success;
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              stateCallSmartContractFunctionButton = ButtonState.idle;
                                            });
                                          });
                                        }
                                        print('Got a Car: ' + result.toString());
                                      } catch (e) {
                                        final snackBar = SnackBar(
                                          duration: Duration(seconds: 10),
                                          content: Text('error: ' + e.toString()),
                                          action: SnackBarAction(
                                            textColor: Theme.of(context).buttonColor,
                                            label: 'OK',
                                            onPressed: () {
                                              // Some code to undo the change.
                                            },
                                          ),
                                        );
                                        Scaffold.of(context).showSnackBar(snackBar);
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.fail;
                                        });
                                        Timer(Duration(seconds: 3), () {
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.idle;
                                          });
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.idle;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ExpansionPanel(
                        isExpanded: _data[3].isExpanded,
                        canTapOnHeader: true,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(_data[3].name),
                          );
                        },
                        body: Form(
                          key: _formKeyTransfer,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Text(
                                  _data[3].shortDiscribe,
                                ),
                                SizedBox(height: 20.0),
                                DropdownButtonFormField(
                                  items: () {
                                    List<DropdownMenuItem> dropList = new List<DropdownMenuItem>();
                                    for (var i = 0; i < vehicleAssetContractService.usersOwnedVehicles.toInt(); i++) {
                                      dropList.add(DropdownMenuItem(value: i, child: Text('Vehicle No.' + (i + 1).toString())));
                                    }
                                    return dropList;
                                  }(),
                                  decoration: InputDecoration().copyWith(hintText: 'Car Index'),
                                  onChanged: (val) => tockenIndex = val,
                                ),
                                SizedBox(height: 20.0),
                                // new TextFormField(
                                //   decoration: InputDecoration().copyWith(hintText: 'To Ethereum address'),
                                //   validator: (val) => val.isEmpty ? 'Enter a valid Vehicle Id' : null,
                                //   onChanged: (val) {
                                //     toAddress = EthereumAddress.fromHex(val);
                                //   },
                                // ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                          key: Key(toAddress.toString()),
                                          initialValue: toAddress,
                                          decoration: InputDecoration().copyWith(hintText: 'To Address'),
                                          validator: (val) => val.isEmpty ? 'Enter a valid To Address' : null,
                                          onChanged: (val) {
                                            toAddress = val;
                                          }),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.qr_code_scanner),
                                      onPressed: () async {
                                        try {
                                          String qrResult = await BarcodeScanner.scan();
                                          print('qrResult: ' + qrResult);
                                          setState(() {
                                            toAddress = qrResult;
                                          });
                                        } on PlatformException catch (ex) {
                                          if (ex.code == BarcodeScanner.CameraAccessDenied) {
                                            toAddress = "Camera permission was denied";
                                            print('qrResult: ' + toAddress);
                                          } else {
                                            toAddress = "Unknown Error $ex";
                                            print('qrResult: ' + toAddress);
                                          }
                                        } on FormatException {
                                          toAddress = "You pressed the back button before scanning anything";
                                          print('qrResult: ' + toAddress);
                                        } catch (ex) {
                                          toAddress = "Unknown Error $ex";
                                          print('qrResult: ' + toAddress);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.0),
                                new ProgressButton.icon(
                                  iconedButtons: {
                                    ButtonState.idle: IconedButton(
                                        text: _data[3].name, icon: Icon(Icons.transform_rounded, color: Colors.white), color: Theme.of(context).buttonColor),
                                    ButtonState.loading: IconedButton(text: "Loading", color: Theme.of(context).buttonColor),
                                    ButtonState.fail:
                                        IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                                    ButtonState.success: IconedButton(
                                        text: "Success",
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        color: Theme.of(context).buttonColor)
                                  },
                                  state: stateCallSmartContractFunctionButton,
                                  onPressed: () async {
                                    if (_formKeyGet.currentState.validate()) {
                                      print('button pressed: ' + _data[3].name);
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.loading;
                                      });
                                      try {
                                        BigInt tokenId = await vehicleAssetContractService.getTockenIdByIndex(BigInt.parse(tockenIndex.toString()));
                                        String result = await vehicleAssetContractService.transferFrom(EthereumAddress.fromHex(toAddress), tokenId);
                                        if (result != null) {
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.success;
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              stateCallSmartContractFunctionButton = ButtonState.idle;
                                            });
                                          });
                                        }
                                        print('Got a Car: ' + result.toString());
                                      } catch (e) {
                                        final snackBar = SnackBar(
                                          duration: Duration(seconds: 10),
                                          content: Text('error: ' + e.toString()),
                                          action: SnackBarAction(
                                            textColor: Theme.of(context).buttonColor,
                                            label: 'OK',
                                            onPressed: () {
                                              // Some code to undo the change.
                                            },
                                          ),
                                        );
                                        Scaffold.of(context).showSnackBar(snackBar);
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.fail;
                                        });
                                        Timer(Duration(seconds: 3), () {
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.idle;
                                          });
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.idle;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(thickness: 2.0, height: 40.0),
                // StreamBuilder(
                //   stream: vehicleManagerContract.addcarAddedEventListStream,
                //   builder: (context, AsyncSnapshot<List<CarAddedEvent>> snapShot) {
                //     if (snapShot.hasError) {
                //       return Text('error: ' + snapShot.toString());
                //     } else if (snapShot.connectionState == ConnectionState.waiting) {
                //       return Text('Add Vehicle Event waiting...');
                //     } else {
                //       return Column(
                //         children: [
                //           Center(
                //             child: Text(
                //               'Added Vehicle History',
                //               style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                //             ),
                //           ),
                //           ...snapShot.data.map(
                //             (event) {
                //               return ListTile(
                //                 title: SelectableText('Vehicle Id: ' + event.carId.toString()),
                //                 subtitle: Text('Vehicle Registered'),
                //               );
                //             },
                //           ).toList(),
                //         ],
                //       );
                //     }
                //   },
                // ),
                // Divider(thickness: 2.0, height: 40.0),
                // StreamBuilder(
                //   stream: vehicleManagerContract.carStateUpdatedEventListStream,
                //   builder: (context, AsyncSnapshot<List<CarStateUpdatedEvent>> snapShot) {
                //     if (snapShot.hasError) {
                //       return Text('error: ' + snapShot.toString());
                //     } else if (snapShot.connectionState == ConnectionState.waiting) {
                //       return Text('RemovePermisionEvent waiting...');
                //     } else {
                //       return Column(
                //         children: [
                //           Center(
                //             child: Text(
                //               'Update Vehicle History',
                //               style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                //             ),
                //           ),
                //           ...snapShot.data.map(
                //             (event) {
                //               return ListTile(
                //                 title: SelectableText('Vehicle Id: ' + event.carId.toString()),
                //                 subtitle: Text('Vehicle Status Updated'),
                //               );
                //             },
                //           ).toList(),
                //         ],
                //       );
                //     }
                //   },
                // ),
              ],
            ),
          ),
        ),
      );
    }
    return Loading(
      loadingMessage: 'Loading Contract . . .',
    );
  }
}
