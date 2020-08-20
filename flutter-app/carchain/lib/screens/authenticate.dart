import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  final _formKey = GlobalKey<FormState>();
  String privateKey = '';
  @override
  Widget build(BuildContext context) {
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
              RaisedButton(
                child: Text(
                  'Sign In',
                ),
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    print(privateKey);
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
