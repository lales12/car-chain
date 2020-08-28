import 'dart:developer';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ImportWallet extends StatefulWidget {
  @override
  _ImportWalletState createState() => _ImportWalletState();
}

class _ImportWalletState extends State<ImportWallet> {
  final _formKey = GlobalKey<FormState>();
  String privateKey = 'Private Key';
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
                    child: TextFormField(
                        controller: _qrTextEditingController,
                        // initialValue: _qrTextEditingController.text,
                        decoration:
                            InputDecoration().copyWith(hintText: 'Private Key'),
                        validator: (val) =>
                            val.isEmpty ? 'Enter a valid Private Key' : null,
                        onChanged: (val) {
                          setState(() => privateKey = val);
                        }),
                  ),
                  IconButton(
                      icon: Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        try {
                          String qrResult = await BarcodeScanner.scan();
                          log('qrResult: ' + qrResult);
                          setState(() {
                            privateKey = qrResult;
                          });
                          _qrTextEditingController.text = qrResult;
                        } on PlatformException catch (ex) {
                          if (ex.code == BarcodeScanner.CameraAccessDenied) {
                            privateKey = "Camera permission was denied";
                          } else {
                            privateKey = "Unknown Error $ex";
                          }
                        } on FormatException {
                          privateKey =
                              "You pressed the back button before scanning anything";
                        } catch (ex) {
                          privateKey = "Unknown Error $ex";
                        }
                      }),
                ],
              ),
              SizedBox(height: 20.0),
              RaisedButton(
                child: Text(
                  'Import',
                ),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    print(privateKey);
                    walletManager.setWalletFromPrivKey(privateKey);
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
