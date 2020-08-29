import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RenderQr extends StatelessWidget {
  final String title;
  final String qrData;
  final String qrMessage;
  final String subTitle;
  RenderQr({this.title, this.qrMessage, this.qrData, this.subTitle});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.0),
            if (qrMessage != '') ...[
              Text(qrMessage),
              SizedBox(height: 20.0),
            ],
            QrImage(
              data: qrData,
              version: QrVersions.auto,
              size: 250,
              gapless: false,
              embeddedImage: AssetImage('assets/hand_car.png'),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: Size(80, 80),
              ),
              errorStateBuilder: (context, err) {
                return Container(
                  child: Center(
                    child: Text(
                      "Uh oh! Something went wrong...",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.0),
            if (subTitle != '') ...[
              Text(subTitle),
              SizedBox(height: 20.0),
            ],
          ],
        ),
      ),
    );
  }
}
