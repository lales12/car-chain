import 'dart:async';

import 'package:carchain/models/AppUserWallet.dart';
import 'package:carchain/services/walletmanager.dart';
import 'package:carchain/util/loading.dart';
import 'package:carchain/util/renderqr.dart';
import 'package:flutter/material.dart';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:provider/provider.dart';
// import 'package:rounded_loading_button/rounded_loading_button.dart';

class AccountProfile extends StatefulWidget {
  @override
  _AccountProfileState createState() => _AccountProfileState();
}

class _AccountProfileState extends State<AccountProfile> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // final RoundedLoadingButtonController _btnController =
    //     new RoundedLoadingButtonController();
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
        title: Text("Account Profile"),
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
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: appUserWallet.isMnemonic
          ? FloatingActionButton.extended(
              label: Text('Change'),
              icon: Icon(Icons.refresh),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    ButtonState stateChangeWalletIndex = ButtonState.idle;
                    return Container(
                      child: StatefulBuilder(builder: (BuildContext context, StateSetter setModalState) {
                        return Container(
                          height: 500,
                          // color: Colors.amber,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        decoration: InputDecoration().copyWith(hintText: 'Account Index Number'),
                                        validator: (val) => val.isEmpty ? 'Enter a valid Index Number' : null,
                                        onChanged: (val) {
                                          walletAccountIndex = int.parse(val);
                                        }),
                                  ),
                                ),
                                ProgressButton.icon(
                                  iconedButtons: {
                                    ButtonState.idle:
                                        IconedButton(text: "Change", icon: Icon(Icons.refresh, color: Colors.white), color: Theme.of(context).buttonColor),
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
                                  state: stateChangeWalletIndex,
                                  onPressed: () async {
                                    if (_formKey.currentState.validate()) {
                                      print('changing account index to: ' + walletAccountIndex.toString());
                                      setModalState(() {
                                        stateChangeWalletIndex = ButtonState.loading;
                                      });

                                      // _btnController.success();

                                      Timer(Duration(seconds: 2), () async {
                                        await walletManager.changeWalletAccountIndex(walletAccountIndex);
                                        Timer(Duration(seconds: 2), () {
                                          setModalState(() {
                                            stateChangeWalletIndex = ButtonState.success;
                                          });
                                          Timer(Duration(seconds: 2), () {
                                            Navigator.pop(context);
                                          });
                                        });
                                      });
                                    } else {
                                      // _btnController.error();
                                      setModalState(() {
                                        stateChangeWalletIndex = ButtonState.fail;
                                      });
                                      Timer(Duration(seconds: 2), () {
                                        // _btnController.stop();
                                        setModalState(() {
                                          stateChangeWalletIndex = ButtonState.idle;
                                        });
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                );
              },
            )
          : null,
    );
  }
}
