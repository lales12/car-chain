import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:ethereum_address/ethereum_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehicle_chain_app/contracts_services/itvmanagercontractservice.dart';
import 'package:vehicle_chain_app/screens/tabs/authorizertab.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/util/loading.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ItvTab extends StatefulWidget {
  @override
  _ItvTabState createState() => _ItvTabState();
}

class _ItvTabState extends State<ItvTab> {
  // nfc
  static const platformMethods = const MethodChannel('carChain.com/methodsChannel');
  static const platformEvents = const EventChannel('carChain.com/getCardInfoEvent');
  static const platformSignEvents = const EventChannel('carChain.com/signEvent');

  String _isNfcAdapterEnabled = 'Unknown Nfc Status.';
  String _nfcCardPubKeyError = 'no error yet';
  String _nfcCardPubKey;
  String _nfcCardMessage;
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
        result == true ? _nfcCardMessage = 'Please attach your KeyCard to your device to Sign.' : _nfcCardMessage = 'Somthing is wrong...';
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
      _nfcCardSignitureList = json.decode(event);
      _nfcCardMessage = "Car Signiture:\n" +
          "R: " +
          '0x' +
          _nfcCardSignitureList['r'] +
          "\n" +
          "S: " +
          '0x' +
          _nfcCardSignitureList['s'] +
          "\n" +
          "V: " +
          (int.parse(_nfcCardSignitureList['v']) + 27).toString();
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
  List<ExpandingItem> _data = [
    ExpandingItem(
      name: 'Inspection Update',
      shortDiscribe: "Update vehicle's inspection state",
      isExpanded: false,
    ),
    ExpandingItem(
      name: 'Inspection Status',
      shortDiscribe: "Get last inspection status",
      isExpanded: false,
    ),
  ];

  final _formKeyUpdateInspection = GlobalKey<FormState>();
  final _formKeyInspectionState = GlobalKey<FormState>();
  String vinId = '';
  ButtonState stateNFCButton = ButtonState.idle;
  String inputFunctionName = '';
  ButtonState stateCallSmartContractFunctionButton = ButtonState.idle;
  String carAddress;
  int selectedvehicleStates;
  final Map<String, int> vehicleStates = {'PASSED': 1, 'NOT_PASSED': 2, 'NEGATIVE': 3};

  Future<void> _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    // hanle tx reciept
    handleTxRecipt(TransactionReceipt recipt) {
      final snackBar = SnackBar(
        duration: Duration(seconds: 10),
        content: Container(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(recipt.status ? 'Transaction Id: ' + bytesToHex(recipt.transactionHash, include0x: true) : 'Transaction Failed'),
              FlatButton(
                child: Text('Open in EtherScan'),
                onPressed: () async {
                  String url = 'https://ropsten.etherscan.io/tx/' + bytesToHex(recipt.transactionHash, include0x: true);
                  await _launchInBrowser(url);
                },
              )
            ],
          ),
        ),
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
    }

    // final authorizerContract = Provider.of<AuthorizerContract>(context);
    // final carManagerContract = Provider.of<CarManager>(context);
    final itvManagerContract = Provider.of<ItvManager>(context);
    final appUserWallet = Provider.of<WalletManager>(context).getAppUserWallet;

    if (appUserWallet != null && itvManagerContract.doneLoading) {
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
                      setState(() {
                        _data[index].isExpanded = !isExpanded;
                      });
                    },
                    children: [
                      ExpansionPanel(
                        isExpanded: _data[0].isExpanded,
                        canTapOnHeader: true,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(_data[0].name),
                          );
                        },
                        body: Form(
                          key: _formKeyUpdateInspection,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Text(
                                  _data[0].shortDiscribe,
                                ),
                                SizedBox(height: 20.0),
                                new TextFormField(
                                  // initialValue: vinId,
                                  decoration: InputDecoration().copyWith(hintText: 'VIN Id'),
                                  validator: (val) => val.isEmpty ? 'Enter a valid VIN Id' : null,
                                  onChanged: (val) {
                                    vinId = val;
                                  },
                                ),
                                SizedBox(height: 20.0),
                                DropdownButtonFormField(
                                  items: vehicleStates.entries.map((entry) {
                                    print('key: ' + entry.key);
                                    return DropdownMenuItem(value: entry.value, child: Text(entry.key));
                                  }).toList(),
                                  decoration: InputDecoration().copyWith(hintText: 'Next vehicle state'),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedvehicleStates = val;
                                    });
                                    log('selected nex state: ' + val.toString());
                                  },
                                ),
                                SizedBox(height: 20.0),
                                Text(_nfcCardMessage != null ? _nfcCardMessage : ''),
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
                                    if (_formKeyUpdateInspection.currentState.validate()) {
                                      print('button pressed: Get Car Signiture');
                                      setState(() {
                                        _nfcCardMessage = "Please attach your device to Vehicle's card";
                                      });
                                      setState(() {
                                        stateNFCButton = ButtonState.loading;
                                      });
                                      try {
                                        Uint8List vinHash = keccak256(Uint8List.fromList(vinId.codeUnits));
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
                                        IconedButton(text: _data[0].name, icon: Icon(Icons.search, color: Colors.white), color: Theme.of(context).buttonColor),
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
                                    if (_formKeyUpdateInspection.currentState.validate()) {
                                      print('button pressed: ' + _data[0].name);
                                      print(vinId);
                                      print(inputFunctionName);
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.loading;
                                      });
                                      try {
                                        Uint8List vinHash = keccak256(Uint8List.fromList(vinId.codeUnits));
                                        Uint8List r = hexToBytes(_nfcCardSignitureList['r']);
                                        Uint8List s = hexToBytes(_nfcCardSignitureList['s']);
                                        BigInt v = BigInt.from(int.parse(_nfcCardSignitureList['v']) + 27);
                                        int vInt = int.parse(_nfcCardSignitureList['v']) + 27;
                                        List<int> rsv = [...r, ...s, vInt];
                                        Uint8List signiture = Uint8List.fromList(rsv);

                                        TransactionReceipt result = await itvManagerContract.updateITV(vinHash, signiture, BigInt.from(selectedvehicleStates));
                                        if (result != null) {
                                          handleTxRecipt(result);
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.success;
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              stateCallSmartContractFunctionButton = ButtonState.idle;
                                            });
                                          });
                                        }
                                        print('done call updateITV: ' + result.status.toString());
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
                      //////////////////////////////////
                      ExpansionPanel(
                        isExpanded: _data[1].isExpanded,
                        canTapOnHeader: true,
                        headerBuilder: (BuildContext context, bool isExpanded) {
                          return ListTile(
                            title: Text(_data[1].name),
                          );
                        },
                        body: Form(
                          key: _formKeyInspectionState,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Text(
                                  _data[1].shortDiscribe,
                                ),
                                SizedBox(height: 20.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                          key: Key(carAddress.toString()),
                                          initialValue: carAddress,
                                          decoration: InputDecoration().copyWith(hintText: 'Vehicle Address'),
                                          validator: (val) => val.isEmpty ? 'Enter a valid Vehicle Address' : null,
                                          onChanged: (val) {
                                            carAddress = val;
                                          }),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.qr_code_scanner),
                                      onPressed: () async {
                                        try {
                                          String qrResult = await BarcodeScanner.scan();
                                          print('qrResult: ' + qrResult);
                                          setState(() {
                                            carAddress = qrResult;
                                          });
                                        } on PlatformException catch (ex) {
                                          if (ex.code == BarcodeScanner.CameraAccessDenied) {
                                            carAddress = "Camera permission was denied";
                                            print('qrResult: ' + carAddress);
                                          } else {
                                            carAddress = "Unknown Error $ex";
                                            print('qrResult: ' + carAddress);
                                          }
                                        } on FormatException {
                                          carAddress = "You pressed the back button before scanning anything";
                                          print('qrResult: ' + carAddress);
                                        } catch (ex) {
                                          carAddress = "Unknown Error $ex";
                                          print('qrResult: ' + carAddress);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.0),
                                new ProgressButton.icon(
                                  iconedButtons: {
                                    ButtonState.idle:
                                        IconedButton(text: _data[1].name, icon: Icon(Icons.search, color: Colors.white), color: Theme.of(context).buttonColor),
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
                                    if (_formKeyInspectionState.currentState.validate()) {
                                      print('button pressed: ' + _data[1].name);
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.loading;
                                      });
                                      try {
                                        ITVInspection result = await itvManagerContract.getITVState(EthereumAddress.fromHex(carAddress));
                                        if (result != null) {
                                          final snackBar = SnackBar(
                                            duration: Duration(seconds: 30),
                                            content: Text('Vehicle \nState: ' + result.state.toString() + '\nDate: ' + result.date.toString()),
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
                                        print('done call getITVState: ' + result.state.toString());
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
                // _buildPanel(_data, authorizerContract, carManagerContract.contractFunctionsList, appUserWallet),
                Divider(thickness: 2.0, height: 40.0),
                StreamBuilder(
                  stream: itvManagerContract.iTVInspectionEventListStream,
                  builder: (context, AsyncSnapshot<List<ITVInspectionEvent>> snapShot) {
                    if (snapShot.hasError) {
                      return Text('error: ' + snapShot.toString());
                    } else if (snapShot.connectionState == ConnectionState.waiting) {
                      return Text('Add Permision Event waiting...');
                    } else {
                      return Column(
                        children: [
                          Center(
                            child: Text(
                              'Technical Inspection History',
                              style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                            ),
                          ),
                          ...snapShot.data.map(
                            (event) {
                              return ListTile(
                                title: Text(event.carId.toString()),
                                subtitle: Text(event.state.toString()),
                              );
                            },
                          ).toList(),
                        ],
                      );
                    }
                  },
                ),
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
