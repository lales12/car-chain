class AppConfig {
  AppConfig() {
    params['dev'] =
        AppConfigParams("http://192.168.0.17:7545", "ws://192.168.0.17:7545/");

    params['ropsten'] = AppConfigParams(
        "https://ropsten.infura.io/v3/628074215a2449eb960b4fe9e95feb09",
        "wss://ropsten.infura.io/ws/v3/628074215a2449eb960b4fe9e95feb09");
  }

  Map<String, AppConfigParams> params = Map<String, AppConfigParams>();
}

class AppConfigParams {
  final String rpc;
  final String ws;
  AppConfigParams(this.rpc, this.ws);
}
