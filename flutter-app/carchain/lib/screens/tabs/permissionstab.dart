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
  ),
  Item(
    name: 'Remove Permission',
    shortDiscribe:
        'Remove permistion to a user to use a function in a smart contract.',
    isExpanded: false,
  ),
  Item(
    name: 'Request Access',
    shortDiscribe: 'Request the Status of your permision',
    isExpanded: false,
  ),
];

class PermissionsTab extends StatefulWidget {
  @override
  _PermissionsTabState createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab> {
  String callContractAddress = '';
  String callFunctionName = '';
  String callToAddress = '';
  @override
  Widget build(BuildContext context) {
    final permissionsContract = Provider.of<PermissionContract>(context);
    if (permissionsContract.doneLoading) {
      print('permistion contract address: ' +
          permissionsContract.contractAddress.toString());
      return Scaffold(
          body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(8.0),
          child: _buildPanel(),
        ),
      ));
    }
    return Loading(
      loadingMessage: 'Loading Contract...',
    );
  }

  Widget _buildPanel() {
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
                        callContractAddress = val;
                      }),
                  SizedBox(height: 20.0),
                  new TextFormField(
                      decoration:
                          InputDecoration().copyWith(hintText: 'Function Name'),
                      validator: (val) =>
                          val.isEmpty ? 'Enter a valid Function Name' : null,
                      onChanged: (val) {
                        callFunctionName = val;
                      }),
                  SizedBox(height: 20.0),
                  new TextFormField(
                      decoration:
                          InputDecoration().copyWith(hintText: 'To Address'),
                      validator: (val) =>
                          val.isEmpty ? 'Enter a valid To Address' : null,
                      onChanged: (val) {
                        callToAddress = val;
                      }),
                  SizedBox(height: 20.0),
                  new RaisedButton(
                    child: Text(
                      item.name,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        print('button pressed: ' + item.name);
                        print(callContractAddress);
                        print(callFunctionName);
                        print(callToAddress);
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
