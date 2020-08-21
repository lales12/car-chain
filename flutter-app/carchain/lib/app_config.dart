// uncoment what you don't use to avoid problem warning

class AppConfig {
  String rpcUrl;
  String wsUrl;
  AppConfig({this.rpcUrl, this.wsUrl});
}

Map<String, String> _dev = {
  'rpcUrl': 'http://192.168.0.17:7545',
  'wsUrl': 'ws://192.168.0.17:7545/'
};

// Map<String, String> _ropsten = {
//   'rpcUrl': 'https://ropsten.infura.io/v3/628074215a2449eb960b4fe9e95feb09',
//   'wsUrl': 'wss://ropsten.infura.io/ws/v3/628074215a2449eb960b4fe9e95feb09'
// };

AppConfig configParams =
    AppConfig(rpcUrl: _dev['rpcUrl'], wsUrl: _dev['wsUrl']);
