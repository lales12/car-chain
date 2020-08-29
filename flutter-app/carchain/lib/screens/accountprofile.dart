import 'dart:async';

import 'package:carchain/models/AppUserWallet.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/loading.dart';
import 'package:carchain/util/renderqr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class AccountProfile extends StatefulWidget {
  @override
  _AccountProfileState createState() => _AccountProfileState();
}

class _AccountProfileState extends State<AccountProfile> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final RoundedLoadingButtonController _btnController =
        new RoundedLoadingButtonController();
    final walletManager = Provider.of<WalletManager>(context);
    AppUserWallet appUserWallet = walletManager.appUserWallet;
    int walletAccountIndex = 0;
    if (appUserWallet == null) {
      return Loading(
        loadingMessage: 'Loading Wallet',
      );
    } else {
      walletAccountIndex = appUserWallet.accountIndex;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("User Account"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(height: 40.0),
            RenderQr(
              title: 'Wallet Address',
              qrMessage: "Wallet's public address",
              qrData: appUserWallet.pubKey.toString(),
              subTitle: appUserWallet.pubKey.toString(),
            ),
            if (appUserWallet.isMnemonic) ...[
              SizedBox(height: 80.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FloatingActionButton.extended(
                      label: Text('Change'),
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              height: 500,
                              // color: Colors.amber,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text("Change Your Wallet's index"),
                                    SizedBox(height: 20.0),
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Form(
                                        key: _formKey,
                                        child: TextFormField(
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration()
                                                .copyWith(
                                                    hintText:
                                                        'Account Index Number'),
                                            validator: (val) => val.isEmpty
                                                ? 'Enter a valid Index Number'
                                                : null,
                                            onChanged: (val) {
                                              walletAccountIndex =
                                                  int.parse(val);
                                            }),
                                      ),
                                    ),
                                    RoundedLoadingButton(
                                        controller: _btnController,
                                        color: Theme.of(context).buttonColor,
                                        child: Text(
                                          'Change',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        onPressed: () async {
                                          if (_formKey.currentState
                                              .validate()) {
                                            print(
                                                'changing account index to: ' +
                                                    walletAccountIndex
                                                        .toString());
                                            await walletManager
                                                .changeWalletAccountIndex(
                                                    walletAccountIndex);
                                            _btnController.success();
                                            Timer(Duration(seconds: 1), () {
                                              Navigator.pop(context);
                                            });
                                          } else {
                                            _btnController.error();
                                            Timer(Duration(seconds: 1), () {
                                              _btnController.stop();
                                            });
                                          }
                                        })
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }
}
