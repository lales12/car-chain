import 'dart:async';
import 'dart:developer';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehicle_chain_app/contracts_services/itvmanagercontractservice.dart';
import 'package:vehicle_chain_app/contracts_services/vehiclemanagercontractservice.dart';
import 'package:vehicle_chain_app/contracts_services/authorizercontractservice.dart';
import 'package:vehicle_chain_app/services/walletmanager.dart';
import 'package:vehicle_chain_app/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ExpandingItem {
  ExpandingItem({
    this.name,
    this.shortDiscribe,
    this.isExpanded = false,
  });

  String name;
  String shortDiscribe;
  bool isExpanded;
}

class InputContract {
  String name;
  String address;
  List<String> functionList;
  InputContract({this.name, this.address});
}

class AuthorizerTab extends StatefulWidget {
  @override
  _AuthorizerTabState createState() => _AuthorizerTabState();
}

class _AuthorizerTabState extends State<AuthorizerTab> {
  List<ExpandingItem> _data = [
    ExpandingItem(
      name: 'Add Permission',
      shortDiscribe: 'Add permistion to a user to use a function in a smart contract.',
      isExpanded: false,
    ),
    ExpandingItem(
      name: 'Remove Permission',
      shortDiscribe: 'Remove permistion to a user to use a function in a smart contract.',
      isExpanded: false,
    ),
    ExpandingItem(
      name: 'Access Status',
      shortDiscribe: 'Request the Status of your permision',
      isExpanded: false,
    ),
  ];

  List<InputContract> contractsList = [
    InputContract(name: 'VehicleManager', address: '0x0'),
    InputContract(name: 'ITVManager', address: '0x1'),
  ];
  final _formKeyAdd = GlobalKey<FormState>();
  final _formKeyRemove = GlobalKey<FormState>();
  final _formKeyRequest = GlobalKey<FormState>();
  String inputContractAddress = '';
  String inputFunctionName = '';
  ButtonState stateCallSmartContractFunctionButton = ButtonState.idle;
  String inputToAddress = '';
  int selectedContractIndex = 0;
  int selectedFunctionIndex = 0;

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

    final authorizerContract = Provider.of<AuthorizerContract>(context);
    final carManagerContract = Provider.of<CarManager>(context);
    final itvManagerContract = Provider.of<ItvManager>(context);
    final appUserWallet = Provider.of<WalletManager>(context).getAppUserWallet;

    if (appUserWallet != null && authorizerContract.doneLoading && carManagerContract.doneLoading && itvManagerContract.doneLoading) {
      // set
      // List<ContractFunction> carManagerFunctionList = carManagerContract.contractFunctionsList;
      inputContractAddress = carManagerContract.contractAddress.toString();
      contractsList[0].address = carManagerContract.contractAddress.toString();
      contractsList[1].address = itvManagerContract.contractAddress.toString();
      contractsList[0].functionList = carManagerContract.contractFunctionsList;
      contractsList[1].functionList = itvManagerContract.contractFunctionsList;
      log('list of carManager funcs: ' + carManagerContract.contractFunctionsList.toString());
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
                      if (authorizerContract.contractOwner != appUserWallet.pubKey) {
                        // i don't like that, well ...
                        index = 2;
                      }
                      setState(() {
                        _data[index].isExpanded = !isExpanded;
                      });
                    },
                    children: [
                      if (authorizerContract.contractOwner == appUserWallet.pubKey) ...[
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
                                  // new TextFormField(
                                  //     initialValue: inputContractAddress,
                                  //     decoration: InputDecoration().copyWith(hintText: 'Contract Address'),
                                  //     validator: (val) => val.isEmpty ? 'Enter a valid Contract Address' : null,
                                  //     onChanged: (val) {
                                  //       inputContractAddress = val;
                                  //     }),
                                  DropdownButtonFormField(
                                    items: contractsList.map((inputContract) {
                                      print('func: ' + inputContract.name);
                                      return DropdownMenuItem(value: inputContract, child: Text(inputContract.name));
                                    }).toList(),
                                    decoration: InputDecoration().copyWith(hintText: 'Contract'),
                                    onChanged: (InputContract val) {
                                      inputContractAddress = val.address;
                                      setState(() {
                                        selectedFunctionIndex = 0;
                                        selectedContractIndex = contractsList.indexOf(val);
                                      });
                                      log('index of selected contract: ' + selectedContractIndex.toString());
                                    },
                                  ),
                                  SizedBox(height: 20.0),
                                  DropdownButtonFormField(
                                    value: contractsList[selectedContractIndex].functionList[selectedFunctionIndex],
                                    items: contractsList[selectedContractIndex].functionList.map((func) {
                                      print('func: ' + func);
                                      return DropdownMenuItem(value: func, child: Text(func.split('(')[0]));
                                    }).toList(),
                                    decoration: InputDecoration().copyWith(hintText: 'Functions'),
                                    onChanged: (val) => inputFunctionName = val,
                                  ),
                                  SizedBox(height: 20.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                            key: Key(inputToAddress),
                                            initialValue: inputToAddress,
                                            decoration: InputDecoration().copyWith(hintText: 'To Address'),
                                            validator: (val) => val.isEmpty ? 'Enter a valid To Address' : null,
                                            onChanged: (val) {
                                              inputToAddress = val;
                                            }),
                                      ),
                                      // Expanded(child: Text(inputToAddress)),
                                      IconButton(
                                        icon: Icon(Icons.qr_code_scanner),
                                        onPressed: () async {
                                          try {
                                            String qrResult = await BarcodeScanner.scan();
                                            print('qrResult: ' + qrResult);
                                            setState(() {
                                              inputToAddress = qrResult;
                                            });
                                          } on PlatformException catch (ex) {
                                            if (ex.code == BarcodeScanner.CameraAccessDenied) {
                                              inputToAddress = "Camera permission was denied";
                                              print('qrResult: ' + inputToAddress);
                                            } else {
                                              inputToAddress = "Unknown Error $ex";
                                              print('qrResult: ' + inputToAddress);
                                            }
                                          } on FormatException {
                                            inputToAddress = "You pressed the back button before scanning anything";
                                            print('qrResult: ' + inputToAddress);
                                          } catch (ex) {
                                            inputToAddress = "Unknown Error $ex";
                                            print('qrResult: ' + inputToAddress);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.0),
                                  new ProgressButton.icon(
                                    iconedButtons: {
                                      ButtonState.idle: IconedButton(
                                          text: _data[0].name, icon: Icon(Icons.privacy_tip, color: Colors.white), color: Theme.of(context).buttonColor),
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
                                      if (_formKeyAdd.currentState.validate()) {
                                        print('button pressed: ' + _data[0].name);
                                        print(inputContractAddress);
                                        print(inputFunctionName);
                                        print(inputToAddress);
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.loading;
                                        });
                                        try {
                                          TransactionReceipt result = await authorizerContract.addPermission(
                                              EthereumAddress.fromHex(inputContractAddress), inputFunctionName, EthereumAddress.fromHex(inputToAddress));
                                          if (result != null) {
                                            handleTxRecipt(result);
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
                                          print('done call tx: ' + result.status.toString());
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
                          isExpanded: _data[1].isExpanded,
                          canTapOnHeader: true,
                          headerBuilder: (BuildContext context, bool isExpanded) {
                            return ListTile(
                              title: Text(_data[1].name),
                            );
                          },
                          body: Form(
                            key: _formKeyRemove,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  SizedBox(height: 20.0),
                                  Text(
                                    _data[1].shortDiscribe,
                                  ),
                                  SizedBox(height: 20.0),
                                  // new TextFormField(
                                  //     initialValue: inputContractAddress,
                                  //     decoration: InputDecoration().copyWith(hintText: 'Contract Address'),
                                  //     validator: (val) => val.isEmpty ? 'Enter a valid Contract Address' : null,
                                  //     onChanged: (val) {
                                  //       inputContractAddress = val;
                                  //     }),
                                  DropdownButtonFormField(
                                    items: contractsList.map((inputContract) {
                                      print('func: ' + inputContract.name);
                                      return DropdownMenuItem(value: inputContract, child: Text(inputContract.name));
                                    }).toList(),
                                    decoration: InputDecoration().copyWith(hintText: 'Contract'),
                                    onChanged: (InputContract val) {
                                      inputContractAddress = val.address;
                                      setState(() {
                                        selectedFunctionIndex = 0;
                                        selectedContractIndex = contractsList.indexOf(val);
                                      });
                                      log('index of selected contract: ' + selectedContractIndex.toString());
                                    },
                                  ),
                                  SizedBox(height: 20.0),
                                  // DropdownButtonFormField(
                                  //   items: carManagerFunctionList.map((func) {
                                  //     print('func: ' + func.encodeName());
                                  //     return DropdownMenuItem(value: func.encodeName(), child: Text(func.name));
                                  //   }).toList(),
                                  //   decoration: InputDecoration().copyWith(hintText: 'Functions'),
                                  //   onChanged: (val) => inputFunctionName = val,
                                  // ),
                                  DropdownButtonFormField(
                                    value: contractsList[selectedContractIndex].functionList[selectedFunctionIndex],
                                    items: contractsList[selectedContractIndex].functionList.map((func) {
                                      print('func: ' + func);
                                      return DropdownMenuItem(value: func, child: Text(func.split('(')[0]));
                                    }).toList(),
                                    decoration: InputDecoration().copyWith(hintText: 'Functions'),
                                    onChanged: (val) => inputFunctionName = val,
                                  ),
                                  SizedBox(height: 20.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: new TextFormField(
                                            key: Key(inputToAddress),
                                            initialValue: inputToAddress,
                                            decoration: InputDecoration().copyWith(hintText: 'To Address'),
                                            validator: (val) => val.isEmpty ? 'Enter a valid To Address' : null,
                                            onChanged: (val) {
                                              inputToAddress = val;
                                            }),
                                      ),
                                      IconButton(
                                          icon: Icon(Icons.qr_code_scanner),
                                          onPressed: () async {
                                            try {
                                              String qrResult = await BarcodeScanner.scan();
                                              print('qrResult: ' + qrResult);
                                              setState(() {
                                                inputToAddress = qrResult;
                                              });
                                            } on PlatformException catch (ex) {
                                              if (ex.code == BarcodeScanner.CameraAccessDenied) {
                                                inputToAddress = "Camera permission was denied";
                                              } else {
                                                inputToAddress = "Unknown Error $ex";
                                              }
                                            } on FormatException {
                                              inputToAddress = "You pressed the back button before scanning anything";
                                            } catch (ex) {
                                              inputToAddress = "Unknown Error $ex";
                                            }
                                          }),
                                    ],
                                  ),
                                  SizedBox(height: 20.0),
                                  new ProgressButton.icon(
                                    iconedButtons: {
                                      ButtonState.idle: IconedButton(
                                          text: _data[1].name, icon: Icon(Icons.privacy_tip, color: Colors.white), color: Theme.of(context).buttonColor),
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
                                      if (_formKeyRemove.currentState.validate()) {
                                        print('button pressed: ' + _data[1].name);
                                        print(inputContractAddress);
                                        print(inputFunctionName);
                                        print(inputToAddress);
                                        setState(() {
                                          stateCallSmartContractFunctionButton = ButtonState.loading;
                                        });
                                        try {
                                          TransactionReceipt result = await authorizerContract.removePermission(
                                              EthereumAddress.fromHex(inputContractAddress), inputFunctionName, EthereumAddress.fromHex(inputToAddress));
                                          if (result != null) {
                                            handleTxRecipt(result);
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
                                          print('done call tx: ' + result.status.toString());
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
                          key: _formKeyRequest,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                SizedBox(height: 20.0),
                                Text(
                                  _data[2].shortDiscribe,
                                ),
                                SizedBox(height: 20.0),
                                // new TextFormField(
                                //     initialValue: inputContractAddress,
                                //     decoration: InputDecoration().copyWith(hintText: 'Contract Address'),
                                //     validator: (val) => val.isEmpty ? 'Enter a valid Contract Address' : null,
                                //     onChanged: (val) {
                                //       inputContractAddress = val;
                                //     }),
                                DropdownButtonFormField(
                                  items: contractsList.map((inputContract) {
                                    print('func: ' + inputContract.name);
                                    return DropdownMenuItem(value: inputContract, child: Text(inputContract.name));
                                  }).toList(),
                                  decoration: InputDecoration().copyWith(hintText: 'Contract'),
                                  onChanged: (InputContract val) {
                                    inputContractAddress = val.address;
                                    setState(() {
                                      selectedFunctionIndex = 0;
                                      selectedContractIndex = contractsList.indexOf(val);
                                    });
                                    log('index of selected contract: ' + selectedContractIndex.toString());
                                  },
                                ),
                                SizedBox(height: 20.0),
                                // DropdownButtonFormField(
                                //   items: carManagerFunctionList.map((func) {
                                //     print('func: ' + func.encodeName());
                                //     return DropdownMenuItem(value: func.encodeName(), child: Text(func.name));
                                //   }).toList(),
                                //   decoration: InputDecoration().copyWith(hintText: 'Functions'),
                                //   onChanged: (val) => inputFunctionName = val,
                                // ),
                                DropdownButtonFormField(
                                  value: contractsList[selectedContractIndex].functionList[selectedFunctionIndex],
                                  items: contractsList[selectedContractIndex].functionList.map((func) {
                                    print('func: ' + func);
                                    return DropdownMenuItem(value: func, child: Text(func.split('(')[0]));
                                  }).toList(),
                                  decoration: InputDecoration().copyWith(hintText: 'Functions'),
                                  onChanged: (val) => inputFunctionName = val,
                                ),
                                SizedBox(height: 20.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: new TextFormField(
                                          key: Key(inputToAddress),
                                          initialValue: inputToAddress,
                                          decoration: InputDecoration().copyWith(hintText: 'To Address'),
                                          validator: (val) => val.isEmpty ? 'Enter a valid To Address' : null,
                                          onChanged: (val) {
                                            inputToAddress = val;
                                          }),
                                    ),
                                    IconButton(
                                        icon: Icon(Icons.qr_code_scanner),
                                        onPressed: () async {
                                          try {
                                            String qrResult = await BarcodeScanner.scan();
                                            print('qrResult: ' + qrResult);
                                            setState(() {
                                              inputToAddress = qrResult;
                                            });
                                          } on PlatformException catch (ex) {
                                            if (ex.code == BarcodeScanner.CameraAccessDenied) {
                                              inputToAddress = "Camera permission was denied";
                                            } else {
                                              inputToAddress = "Unknown Error $ex";
                                            }
                                          } on FormatException {
                                            inputToAddress = "You pressed the back button before scanning anything";
                                          } catch (ex) {
                                            inputToAddress = "Unknown Error $ex";
                                          }
                                        }),
                                  ],
                                ),
                                SizedBox(height: 20.0),
                                new ProgressButton.icon(
                                  iconedButtons: {
                                    ButtonState.idle: IconedButton(
                                        text: _data[2].name, icon: Icon(Icons.privacy_tip, color: Colors.white), color: Theme.of(context).buttonColor),
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
                                    if (_formKeyRequest.currentState.validate()) {
                                      print('button pressed: ' + _data[2].name);
                                      print(inputContractAddress);
                                      print(inputFunctionName);
                                      print(inputToAddress);
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.loading;
                                      });
                                      try {
                                        bool result = await authorizerContract.requestAccess(
                                            EthereumAddress.fromHex(inputContractAddress), inputFunctionName, EthereumAddress.fromHex(inputToAddress));
                                        if (result != null) {
                                          if (result) {
                                            final snackBar = SnackBar(
                                              duration: Duration(seconds: 10),
                                              content: Text('Access is granted.'),
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
                                          } else {
                                            final snackBar = SnackBar(
                                              duration: Duration(seconds: 10),
                                              content: Text('Access is not granted.'),
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
                                          setState(() {
                                            stateCallSmartContractFunctionButton = ButtonState.success;
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              stateCallSmartContractFunctionButton = ButtonState.idle;
                                            });
                                          });
                                        }
                                        print('done call have access: ' + result.toString());
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
                  stream: authorizerContract.addPermissionEventHistoryStream,
                  builder: (context, AsyncSnapshot<List<AddPermisionEvent>> snapShot) {
                    if (snapShot.hasError) {
                      return Text('error: ' + snapShot.toString());
                    } else if (snapShot.connectionState == ConnectionState.waiting) {
                      return Text('Add Permision Event waiting...');
                    } else {
                      return Column(
                        children: [
                          Center(
                            child: Text(
                              'Added Authorizations History',
                              style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                            ),
                          ),
                          ...snapShot.data.map(
                            (event) {
                              return ListTile(
                                title: Text(event.method.split('(')[0].toString()),
                                subtitle: Text(event.to.toString()),
                              );
                            },
                          ).toList(),
                        ],
                      );
                    }
                  },
                ),
                Divider(thickness: 2.0, height: 40.0),
                StreamBuilder(
                  stream: authorizerContract.removePermissionEventHistoryStream,
                  builder: (context, AsyncSnapshot<List<RemovePermisionEvent>> snapShot) {
                    if (snapShot.hasError) {
                      return Text('error: ' + snapShot.toString());
                    } else if (snapShot.connectionState == ConnectionState.waiting) {
                      return Text('RemovePermisionEvent waiting...');
                    } else {
                      return Column(
                        children: [
                          Center(
                            child: Text(
                              'Remove Authorizations History',
                              style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                            ),
                          ),
                          ...snapShot.data.map(
                            (event) {
                              return ListTile(
                                title: Text(event.method.split('(')[0].toString()),
                                subtitle: Text(event.to.toString()),
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
