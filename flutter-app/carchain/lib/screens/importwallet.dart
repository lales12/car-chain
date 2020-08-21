import 'package:carchain/services/walletmanager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImportWallet extends StatefulWidget {
  @override
  _ImportWalletState createState() => _ImportWalletState();
}

class _ImportWalletState extends State<ImportWallet> {
  final _formKey = GlobalKey<FormState>();
  String privateKey = '';

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
              TextFormField(
                  decoration:
                      InputDecoration().copyWith(hintText: 'Private Key'),
                  validator: (val) =>
                      val.isEmpty ? 'Enter a valid Private Key' : null,
                  onChanged: (val) {
                    setState(() => privateKey = val);
                  }),
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
