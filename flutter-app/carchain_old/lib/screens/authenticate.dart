import 'package:carchain/services/address_service.dart';
import 'package:carchain/services/configuration_service.dart';
import 'package:carchain/services/notifier_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  final _formKey = GlobalKey<FormState>();
  String privateKey = '';

  @override
  Widget build(BuildContext context) {
    final configService = Provider.of<ConfigurationService>(context);
    AddressService addressService = AddressService(configService);
    return Scaffold(
      appBar: AppBar(
        title: Text('Log In'),
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
                'Login to Your Account',
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
              Consumer<NotifierService>(
                builder: (context, NotifierService notifierService, child) =>
                    RaisedButton(
                  child: Text(
                    'Sign In',
                  ),
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      print(privateKey);
                      await addressService.setupFromPrivateKey(privateKey);
                      notifierService.updateNotifier();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
