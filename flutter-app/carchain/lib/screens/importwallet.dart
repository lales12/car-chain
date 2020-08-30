import 'dart:developer';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                        decoration: InputDecoration().copyWith(
                            hintText:
                                (_walletTypeEnum == WalletTypeEnum.privateKey)
                                    ? 'Private Key'
                                    : 'Mnemonic Words'),
                        validator: (val) =>
                            val.isEmpty ? 'Enter a valid Private Key' : null,
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
              RaisedButton(
                child: Text(
                  'Import',
                ),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    if (_walletTypeEnum == WalletTypeEnum.privateKey) {
                      log('importing private key: ' + formFieldInputTex);
                      walletManager.setupWalletFromPrivKey(formFieldInputTex);
                    } else {
                      log('importing mnemonic words: ' + formFieldInputTex);
                      walletManager.setupWalletFromMnemonic(formFieldInputTex);
                    }
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
