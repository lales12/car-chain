import 'dart:async';

import 'package:carchain/contracts_services/permissions.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:web3dart/credentials.dart';

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
    name: 'Add Permission',
    shortDiscribe:
        'Add permistion to a user to use a function in a smart contract.',
    isExpanded: false,
  ),
  Item(
    name: 'Remove Permission',
    shortDiscribe:
        'Remove permistion to a user to use a function in a smart contract.',
    isExpanded: false,
  ),
  Item(
    name: 'Access Status',
    shortDiscribe: 'Request the Status of your permision',
    isExpanded: false,
  ),
];

class PermissionsTab extends StatefulWidget {
  @override
  _PermissionsTabState createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab> {
  String inputContractAddress = '';
  String inputFunctionName = '';
  String inputToAddress = '';

  @override
  Widget build(BuildContext context) {
    final permissionsContract = Provider.of<PermissionContract>(context);
    if (permissionsContract.doneLoading) {
      print('permistion contract address: ' +
          permissionsContract.contractAddress.toString());
      return Scaffold(
          body: SingleChildScrollView(
        child: Column(
          // padding: EdgeInsets.all(8.0),
          children: [
            _buildPanel(_data, permissionsContract),
            SizedBox(height: 20.0),
            StreamBuilder(
                stream: permissionsContract.addPermissionEventStream,
                builder:
                    (context, AsyncSnapshot<List<AddPermisionEvent>> snapShot) {
                  if (snapShot.hasError) {
                    return Text('error: ' + snapShot.toString());
                  } else if (snapShot.connectionState ==
                      ConnectionState.waiting) {
                    return Text('AddPermisionEvent waiting...');
                  } else {
                    return Text(
                        'added data: ' + snapShot.data.length.toString());
                  }
                }),
            SizedBox(height: 20.0),
            StreamBuilder(
                stream: permissionsContract.removePermissionEventStream,
                builder:
                    (context, AsyncSnapshot<RemovePermisionEvent> snapShot) {
                  if (snapShot.hasError) {
                    return Text('error: ' + snapShot.toString());
                  } else if (snapShot.connectionState ==
                      ConnectionState.waiting) {
                    return Text('RemovePermisionEvent waiting...');
                  } else {
                    return Text('removed data: ' + snapShot.data.method);
                  }
                }),
          ],
        ),
      ));
    }
    return Loading(
      loadingMessage: 'Loading Contract...',
    );
  }

  Widget _buildPanel(List<Item> _data, PermissionContract permissionsContract) {
    return ExpansionPanelList(
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
      children: _data.map<ExpansionPanel>((Item item) {
        GlobalKey<FormState> _formKey = GlobalKey<FormState>();
        final RoundedLoadingButtonController _btnController =
            new RoundedLoadingButtonController();
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(item.name),
            );
          },
          body: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 20.0),
                  Text(
                    item.shortDiscribe,
                  ),
                  SizedBox(height: 20.0),
                  new TextFormField(
                      decoration: InputDecoration()
                          .copyWith(hintText: 'Contract Address'),
                      validator: (val) =>
                          val.isEmpty ? 'Enter a valid Contract Address' : null,
                      onChanged: (val) {
                        inputContractAddress = val;
                      }),
                  SizedBox(height: 20.0),
                  new TextFormField(
                      decoration:
                          InputDecoration().copyWith(hintText: 'Function Name'),
                      validator: (val) =>
                          val.isEmpty ? 'Enter a valid Function Name' : null,
                      onChanged: (val) {
                        inputFunctionName = val;
                      }),
                  SizedBox(height: 20.0),
                  new TextFormField(
                      decoration:
                          InputDecoration().copyWith(hintText: 'To Address'),
                      validator: (val) =>
                          val.isEmpty ? 'Enter a valid To Address' : null,
                      onChanged: (val) {
                        inputToAddress = val;
                      }),
                  SizedBox(height: 20.0),
                  new RoundedLoadingButton(
                    color: Theme.of(context).primaryColor,
                    controller: _btnController,
                    child: Text(
                      item.name,
                      style:
                          TextStyle(color: Theme.of(context).primaryColorLight),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        print('button pressed: ' + item.name);
                        print(inputContractAddress);
                        print(inputFunctionName);
                        print(inputToAddress);
                        try {
                          switch (item.name) {
                            case 'Add Permission':
                              String result =
                                  await permissionsContract.addPermission(
                                      EthereumAddress.fromHex(
                                          inputContractAddress),
                                      inputFunctionName,
                                      EthereumAddress.fromHex(inputToAddress));
                              if (result != null) {
                                _btnController.success();
                                Timer(Duration(seconds: 3), () {
                                  _btnController.stop();
                                });
                              }
                              print('done call tx: ' + result);
                              break;
                            case 'Remove Permission':
                              String result =
                                  await permissionsContract.removePermission(
                                      EthereumAddress.fromHex(
                                          inputContractAddress),
                                      inputFunctionName,
                                      EthereumAddress.fromHex(inputToAddress));
                              if (result != null) {
                                _btnController.success();
                                Timer(Duration(seconds: 3), () {
                                  _btnController.stop();
                                });
                              }
                              print('done call tx: ' + result);
                              break;
                            case 'Access Status':
                              bool result =
                                  await permissionsContract.requestAccess(
                                      EthereumAddress.fromHex(
                                          inputContractAddress),
                                      inputFunctionName,
                                      EthereumAddress.fromHex(inputToAddress));
                              if (result != null) {
                                _btnController.success();
                                Timer(Duration(seconds: 3), () {
                                  _btnController.stop();
                                });
                              }
                              print('done call have access: ' +
                                  result.toString());
                              break;
                            default:
                          }
                        } catch (e) {
                          print('error: ' + e.toString());
                          _btnController.error();
                          Timer(Duration(seconds: 3), () {
                            _btnController.stop();
                          });
                        }
                      } else {
                        _btnController.reset();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          isExpanded: item.isExpanded,
        );
      }).toList(),
    );
  }
}
