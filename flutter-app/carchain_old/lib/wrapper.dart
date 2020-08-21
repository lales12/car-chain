import 'package:carchain/screens/authenticate.dart';
import 'package:carchain/screens/home.dart';
import 'package:carchain/services/notifier_service.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    // either return Home or Authenticate widget

    if (NotifierService().isSetupWallet) {
      return Home();
    } else {
      return Authenticate();
    }
  }
}
