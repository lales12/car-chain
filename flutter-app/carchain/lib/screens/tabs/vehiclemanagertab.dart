import 'dart:async';

import 'package:carchain/contracts_services/vehiclemanagercontractservice.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';

class Item {
  Item({
    this.name,
    this.shortDiscribe,
    this.isExpanded = false,
  });

  String name;
  String shortDiscribe;
  bool isExpanded;
}

List<Item> _data = [
  Item(
    name: 'Add Vehicle',
    shortDiscribe: 'Register a new vehicle on the blockchain.',
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
];

class VehicleManagerTab extends StatefulWidget {
  @override
  _VehicleManagerTabState createState() => _VehicleManagerTabState();
}

class _VehicleManagerTabState extends State<VehicleManagerTab> {
  final _formKeyAdd = GlobalKey<FormState>();
  final _formKeyUpdate = GlobalKey<FormState>();
  final _formKeyGet = GlobalKey<FormState>();
  final Map<String, int> vehicleStates = {'SHIPPED': 1, 'FOR_SALE': 2, 'PROCESSING_SALE': 3, 'SOLD': 4, 'PROCESSING_REGISTER': 5, 'REGISTERED': 6};
  final Map<String, int> vehicleTypes = {'TWO_WHEEL': 1, 'THREE_WHEEL': 2, 'FOUR_WHEEL': 3, 'HEAVY': 4, 'AGRICULTURE': 5, 'SERVICE': 6};
  // input for function add Vehicle
  String licensePlate;
  int vehicleType;
  // input for get car function
  int tockenIndex;
  // input update car state
  BigInt inputVehicleTockenId;
  int vehicleState;

  ButtonState stateCallSmartContractFunctionButton = ButtonState.idle;

  @override
  Widget build(BuildContext context) {
    final vehicleManagerContract = Provider.of<CarManager>(context);
    final appUserWallet = Provider.of<WalletManager>(context).appUserWallet;
    if (appUserWallet != null && vehicleManagerContract.doneLoading) {
      //logs
      print('vehicleManagerTab Contract address: ' + vehicleManagerContract.contractAddress.toString());
      print('vehicleManagerTab Contract User address: ' + vehicleManagerContract.userAddress.toString());

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
                      // if (vehicleManagerContract.contractOwner != appUserWallet.pubKey) {
                      //   // i don't like that, well ...
                      //   index = 2;
                      // }
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
                                  decoration: InputDecoration().copyWith(hintText: 'License Plate'),
                                  validator: (val) => val.isEmpty ? 'Enter a valid License Plate' : null,
                                  onChanged: (val) {
                                    licensePlate = val;
                                  },
                                ),
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
                                    if (_formKeyAdd.currentState.validate()) {
                                      print('button pressed: ' + _data[0].name);
                                      print(licensePlate);
                                      print(vehicleType);
                                      setState(() {
                                        stateCallSmartContractFunctionButton = ButtonState.loading;
                                      });
                                      try {
                                        String result = await vehicleManagerContract.addCar(licensePlate, BigInt.parse(vehicleType.toString()));
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
                                    ButtonState.idle:
                                        IconedButton(text: _data[1].name, icon: Icon(Icons.update, color: Colors.white), color: Theme.of(context).buttonColor),
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
                                        String result =
                                            await vehicleManagerContract.updateCarState(inputVehicleTockenId, BigInt.parse(vehicleState.toString()));
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
                                    for (var i = 0; i < /*vehicleManagerContract.usersOwnedVehicles.toInt()*/ 2; i++) {
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
                                      // setState(() {
                                      //   stateCallSmartContractFunctionButton = ButtonState.loading;
                                      // });
                                      // try {
                                      //   Car result = await vehicleManagerContract.getCar(BigInt.parse(tockenIndex.toString()));
                                      //   if (result != null) {
                                      //     final snackBar = SnackBar(
                                      //       duration: Duration(seconds: 30),
                                      //       content: Text('Your Vehicle \nid: ' +
                                      //           result.id.toString() +
                                      //           '\nLicense Plate: ' +
                                      //           result.licensePlate +
                                      //           '\nCar Type: ' +
                                      //           vehicleTypes.keys.firstWhere((k) => vehicleTypes[k] == result.carType.toInt(), orElse: () => null) +
                                      //           '\nCar State: ' +
                                      //           vehicleStates.keys.firstWhere((k) => vehicleStates[k] == result.carState.toInt(), orElse: () => null)),
                                      //       action: SnackBarAction(
                                      //         textColor: Theme.of(context).buttonColor,
                                      //         label: 'OK',
                                      //         onPressed: () {
                                      //           // Some code to undo the change.
                                      //         },
                                      //       ),
                                      //     );
                                      //     // Find the Scaffold in the widget tree and use
                                      //     // it to show a SnackBar.
                                      //     Scaffold.of(context).showSnackBar(snackBar);

                                      //     setState(() {
                                      //       stateCallSmartContractFunctionButton = ButtonState.success;
                                      //     });
                                      //     Timer(Duration(seconds: 3), () {
                                      //       setState(() {
                                      //         stateCallSmartContractFunctionButton = ButtonState.idle;
                                      //       });
                                      //     });
                                      //   }
                                      //   print('Got a Car: ' + result.toString());
                                      // } catch (e) {
                                      //   final snackBar = SnackBar(
                                      //     duration: Duration(seconds: 10),
                                      //     content: Text('error: ' + e.toString()),
                                      //     action: SnackBarAction(
                                      //       textColor: Theme.of(context).buttonColor,
                                      //       label: 'OK',
                                      //       onPressed: () {
                                      //         // Some code to undo the change.
                                      //       },
                                      //     ),
                                      //   );
                                      //   Scaffold.of(context).showSnackBar(snackBar);
                                      //   setState(() {
                                      //     stateCallSmartContractFunctionButton = ButtonState.fail;
                                      //   });
                                      //   Timer(Duration(seconds: 3), () {
                                      //     setState(() {
                                      //       stateCallSmartContractFunctionButton = ButtonState.idle;
                                      //     });
                                      //   });
                                      // }
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
                StreamBuilder(
                  stream: vehicleManagerContract.addcarAddedEventListStream,
                  builder: (context, AsyncSnapshot<List<CarAddedEvent>> snapShot) {
                    if (snapShot.hasError) {
                      return Text('error: ' + snapShot.toString());
                    } else if (snapShot.connectionState == ConnectionState.waiting) {
                      return Text('Add Vehicle Event waiting...');
                    } else {
                      return Column(
                        children: [
                          Center(
                            child: Text(
                              'Added Vehicle History',
                              style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                            ),
                          ),
                          ...snapShot.data.map(
                            (event) {
                              return ListTile(
                                title: Text('Vehicle Id: ' + event.carId.toString()),
                                subtitle: Text('Vehicle Registered'),
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
                  stream: vehicleManagerContract.carStateUpdatedEventListStream,
                  builder: (context, AsyncSnapshot<List<CarStateUpdatedEvent>> snapShot) {
                    if (snapShot.hasError) {
                      return Text('error: ' + snapShot.toString());
                    } else if (snapShot.connectionState == ConnectionState.waiting) {
                      return Text('RemovePermisionEvent waiting...');
                    } else {
                      return Column(
                        children: [
                          Center(
                            child: Text(
                              'Update Vehicle History',
                              style: TextStyle(fontSize: 18.0, color: Theme.of(context).primaryColorLight),
                            ),
                          ),
                          ...snapShot.data.map(
                            (event) {
                              return ListTile(
                                title: Text('Vehicle Id: ' + event.carId.toString()),
                                subtitle: Text('Vehicle Status Updated'),
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
