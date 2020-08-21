import 'package:carchain/app_config.dart';
import 'package:carchain/services/address_service.dart';
import 'package:carchain/services/configuration_service.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

Future<List<SingleChildWidget>> createProviders(AppConfigParams params) async {
  final client = Web3Client(params.rpc, Client(), socketConnector: () {
    return IOWebSocketChannel.connect(params.ws).cast<String>();
  });

  final sharedPrefs = await SharedPreferences.getInstance();
  final configurationService = ConfigurationService(sharedPrefs);
  final addressService = AddressService(configurationService);

  return [
    Provider.value(value: addressService),
    Provider.value(value: configurationService),
  ];
}
