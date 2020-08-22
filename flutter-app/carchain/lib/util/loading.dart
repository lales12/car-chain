import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatefulWidget {
  final String loadingMessage;
  const Loading({Key key, this.loadingMessage = 'Loading...'})
      : super(key: key);
  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColorLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCube(
              color: Theme.of(context).accentColor,
              size: 50.0,
            ),
            SizedBox(
              height: 20.0,
            ),
            Text(
              widget.loadingMessage,
              style: TextStyle(
                  fontSize: 18.0, color: Theme.of(context).accentColor),
            )
          ],
        ),
      ),
    );
  }
}
