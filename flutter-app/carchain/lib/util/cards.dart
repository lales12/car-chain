import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class IconCountCard extends StatelessWidget {
  final Icon cardIcon;
  final String count;
  final String cardTitle;
  final String subTitle;
  IconCountCard({this.cardIcon, this.count, this.cardTitle, this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(cardTitle),
        leading: cardIcon,
        trailing: count != null
            ? Text(count)
            : SpinKitFadingCircle(color: Theme.of(context).accentColor),
        subtitle: Text(subTitle),
      ),
    );
  }
}
