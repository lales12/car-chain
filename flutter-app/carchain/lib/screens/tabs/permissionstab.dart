import 'package:carchain/contracts_services/permissions.dart';
import 'package:carchain/util/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // callFunction: permissionsContract.addPermission,
  ),
  Item(
    name: 'Remove Permission',
    shortDiscribe:
        'Remove permistion to a user to use a function in a smart contract.',
    isExpanded: false,
    // callFunction: permissionsContract.removePermission,
  ),
  Item(
    name: 'Access Status',
    shortDiscribe: 'Request the Status of your permision',
    isExpanded: false,
    // callFunction: permissionsContract.requestAccess,
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
      // print('permistion contract address: ' +
      //     permissionsContract.contractAddress.toString());
      print(permissionsContract.addPermisionEvent ?? 'no event yet');
      return Scaffold(
          body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(8.0),
          child: _buildPanel(_data, permissionsContract),
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
                  new RaisedButton(
                    child: Text(
                      item.name,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        print('button pressed: ' + item.name);
                        print(inputContractAddress);
                        print(inputFunctionName);
                        print(inputToAddress);
                        switch (item.name) {
                          case 'Add Permission':
                            String result =
                                await permissionsContract.addPermission(
                                    EthereumAddress.fromHex(
                                        inputContractAddress),
                                    inputFunctionName,
                                    EthereumAddress.fromHex(inputToAddress));
                            print('done call tx: ' + result);
                            break;
                          case 'Remove Permission':
                            String result =
                                await permissionsContract.removePermission(
                                    EthereumAddress.fromHex(
                                        inputContractAddress),
                                    inputFunctionName,
                                    EthereumAddress.fromHex(inputToAddress));
                            print('done call tx: ' + result);
                            break;
                          case 'Access Status':
                            bool result =
                                await permissionsContract.requestAccess(
                                    EthereumAddress.fromHex(
                                        inputContractAddress),
                                    inputFunctionName,
                                    EthereumAddress.fromHex(inputToAddress));
                            print('done call tx: ' + result.toString());
                            break;
                          default:
                        }
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
