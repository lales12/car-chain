import 'dart:async';
import 'dart:developer';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';

enum WalletTypeEnum { privateKey, mnemonic }

class ImportWallet extends StatefulWidget {
  @override
  _ImportWalletState createState() => _ImportWalletState();
}

class _ImportWalletState extends State<ImportWallet> {
  WalletTypeEnum _walletTypeEnum = WalletTypeEnum.privateKey;
  final _formKey = GlobalKey<FormState>();
  String formFieldInputTex = '';
  TextEditingController _qrTextEditingController = TextEditingController();
  ButtonState stateImportWalletButton = ButtonState.idle;

  @override
  Widget build(BuildContext context) {
    final walletManager = Provider.of<WalletManager>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Wallet'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Select A Network',
              ),
              SizedBox(height: 20.0),
              DropdownButtonFormField(
                items: walletManager.networkConfigs.entries.map<DropdownMenuItem<String>>((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.key),
                  );
                }).toList(),
                decoration: InputDecoration().copyWith(hintText: 'Network'),
                onChanged: (String newValue) {
                  print('network is setting to: ' + newValue);
                  walletManager.changeAppNetwork(newValue);
                },
              ),
              SizedBox(height: 20.0),
              Text(
                'Import A Wallet',
              ),
              SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Private Key'),
                      leading: Radio(
                        activeColor: Theme.of(context).primaryColorLight,
                        value: WalletTypeEnum.privateKey,
                        groupValue: _walletTypeEnum,
                        onChanged: (WalletTypeEnum value) {
                          setState(() {
                            _walletTypeEnum = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Mnemonic'),
                      leading: Radio(
                        activeColor: Theme.of(context).primaryColorLight,
                        value: WalletTypeEnum.mnemonic,
                        groupValue: _walletTypeEnum,
                        onChanged: (WalletTypeEnum value) {
                          setState(() {
                            _walletTypeEnum = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                        textAlignVertical: TextAlignVertical.center,
                        controller: _qrTextEditingController,
                        // initialValue: _qrTextEditingController.text,
                        decoration: InputDecoration().copyWith(hintText: (_walletTypeEnum == WalletTypeEnum.privateKey) ? 'Private Key' : 'Mnemonic Words'),
                        validator: (val) => val.isEmpty ? 'Enter a valid Private Key' : null,
                        minLines: 2,
                        maxLines: 5,
                        onChanged: (val) {
                          setState(() => formFieldInputTex = val);
                        }),
                  ),
                  if (_walletTypeEnum == WalletTypeEnum.privateKey) ...[
                    IconButton(
                        icon: Icon(Icons.qr_code_scanner),
                        onPressed: () async {
                          try {
                            String qrResult = await BarcodeScanner.scan();
                            log('qrResult: ' + qrResult);
                            setState(() {
                              formFieldInputTex = qrResult;
                            });
                            _qrTextEditingController.text = qrResult;
                          } on PlatformException catch (ex) {
                            if (ex.code == BarcodeScanner.CameraAccessDenied) {
                              log("Camera permission was denied");
                            } else {
                              log("Unknown Error $ex");
                            }
                          } on FormatException {
                            log("You pressed the back button before scanning anything");
                          } catch (ex) {
                            log("Unknown Error $ex");
                          }
                        }),
                  ],
                ],
              ),
              SizedBox(height: 20.0),
              ProgressButton.icon(
                iconedButtons: {
                  ButtonState.idle: IconedButton(text: 'Import', icon: Icon(Icons.download_sharp, color: Colors.white), color: Theme.of(context).buttonColor),
                  ButtonState.loading: IconedButton(text: "Changing", color: Theme.of(context).buttonColor),
                  ButtonState.fail: IconedButton(text: "Failed", icon: Icon(Icons.cancel, color: Colors.white), color: Theme.of(context).accentColor),
                  ButtonState.success: IconedButton(
                      text: "Success",
                      icon: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                      ),
                      color: Theme.of(context).buttonColor)
                },
                state: stateImportWalletButton,
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    setState(() {
                      stateImportWalletButton = ButtonState.loading;
                    });
                    Timer(Duration(seconds: 2), () {
                      try {
                        if (_walletTypeEnum == WalletTypeEnum.privateKey) {
                          log('importing private key: ' + formFieldInputTex);
                          walletManager.setupWalletFromPrivKey(formFieldInputTex);
                        } else {
                          log('importing mnemonic words: ' + formFieldInputTex);
                          walletManager.setupWalletFromMnemonic(formFieldInputTex);
                        }
                        setState(() {
                          stateImportWalletButton = ButtonState.success;
                        });
                      } catch (e) {
                        log(e);
                        setState(() {
                          stateImportWalletButton = ButtonState.fail;
                        });
                      }
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
