// uncoment what you don't use to avoid problem warning

class AppConfig {
  String rpcUrl;
  String wsUrl;
  String networkId;
  AppConfig({this.rpcUrl, this.wsUrl, this.networkId});
}

// Map<String, String> _dev = {'rpcUrl': 'http://192.168.0.17:7545', 'wsUrl': 'ws://192.168.0.17:7545/', 'net_id': '5777'};

Map<String, String> _ropsten = {
  'rpcUrl': 'https://ropsten.infura.io/v3/901529b147734743b907456f78d890cb',
  'wsUrl': 'wss://ropsten.infura.io/ws/v3/901529b147734743b907456f78d890cb',
  'net_id': '3'
};

AppConfig configParams = AppConfig(rpcUrl: _ropsten['rpcUrl'], wsUrl: _ropsten['wsUrl'], networkId: _ropsten['net_id']);
