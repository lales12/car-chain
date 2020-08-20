import 'package:carchain/screens/authenticate.dart';
import 'package:carchain/screens/home.dart';
import 'package:carchain/services/configuration_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    // either return Home or Authenticate widget
    final configService = Provider.of<ConfigurationService>(context);

    if (configService.didSetupWallet()) {
      return Home();
    } else {
      return Authenticate();
    }
  }
}
