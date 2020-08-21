import 'package:carchain/app_config.dart';
import 'package:carchain/services/notifier_service.dart';
import 'package:carchain/services_provider.dart';
import 'package:carchain/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void main() async {
  // bootstrapping;
  WidgetsFlutterBinding.ensureInitialized();
  final appConfigProvider = await createProviders(AppConfig().params["dev"]);
  runApp(MyApp(appConfigProvider));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  MyApp(this.appConfigProvider);
  final List<SingleChildWidget> appConfigProvider;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appConfigProvider,
      child: ChangeNotifierProvider(
        create: (_) => NotifierService(),
        child: Consumer<NotifierService>(
            builder: (context, NotifierService notifierService, child) {
          return MaterialApp(
            title: 'Car Chain',
            theme: ThemeData(
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                inputDecorationTheme:
                    InputDecorationTheme(contentPadding: EdgeInsets.all(5.0))),
            home: Wrapper(),
          );
        }),
      ),
    );
  }
}
