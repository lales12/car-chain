module.exports = {
	networks: {
		development: {
			host: "192.168.0.17",
			port: 7545,
			network_id: "5777",
		},
		advanced: {
			websockets: true, // Enable EventEmitter interface for web3 (default: false)
		},
	},
	contracts_build_directory: "./src/abis/",
	compilers: {
		solc: {
			version: "0.5.16",
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};
