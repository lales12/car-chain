const HDWalletProvider = require("truffle-hdwallet-provider");
const infuraKey = "d139992fcddd4999999d7c23b6a74dee";
const testMnemonic = "yard decline apology bounce earn inform again pride usage square ethics lazy".trim();
module.exports = {
	networks: {
		development: {
			host: "192.168.0.17",
			port: 7545,
			network_id: "5777",
		},
		ropsten: {
			provider: () => new HDWalletProvider(testMnemonic, `https://ropsten.infura.io/v3/901529b147734743b907456f78d890cb`),
			network_id: 3, // Ropsten's id
			// gas: 5500000, // Ropsten has a lower block limit than mainnet
			confirmations: 0, // # of confs to wait between deployments. (default: 0)
			timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
			skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
		},
		advanced: {
			websockets: true, // Enable EventEmitter interface for web3 (default: false)
		},
	},
	contracts_build_directory: "./abis/",
	compilers: {
		solc: {
			version: "0.6.6",
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};
