module.exports = async (deployer, networks, accounts) => {
	const authorizeContract = artifacts.require("Authorizer");
	const baseContract = artifacts.require("BaseManager");
	const carAssetContract = artifacts.require("CarAsset");
	const carManagerContract = artifacts.require("CarManager");
	const iTVManagerConctract = artifacts.require("ITVManager");
	const test = artifacts.require("Test");

	let carAssetContractAddress;
	let authorizeContractAddress;

	// let instance_carAssetContract = await deployer.deploy(carAssetContract);
	// let instance_authorizeContract = await deployer.deploy(authorizeContract);

	// let deployed_carAssetContract =  await instance_carAssetContract.deployed();
	// let deployed_authorizeContract =  await instance_authorizeContract.deployed();
	
	// deployer.deploy(baseContract, deployed_authorizeContract.address, deployed_carAssetContract.address);
	// deployer.deploy(carManagerContract, deployed_authorizeContract.address, deployed_carAssetContract.address);
	// deployer.deploy(iTVManagerConctract, deployed_authorizeContract.address, deployed_carAssetContract.address);

	deployer.deploy(carAssetContract).then(function (carAssetContract_deployed) {
		carAssetContractAddress = carAssetContract_deployed.address;

		return deployer.deploy(authorizeContract).then(function (authorizeContract_deployed) {
			authorizeContractAddress = authorizeContract_deployed.address;

			return deployer.deploy(baseContract, authorizeContractAddress, carAssetContractAddress).then(function (baseContract) {
				return deployer
					.deploy(carManagerContract, authorizeContractAddress, carAssetContractAddress)
					.then(function (carManagerContract) {
						return deployer.deploy(iTVManagerConctract, authorizeContractAddress, carAssetContractAddress);
					});
			});
		});
	});

	deployer.deploy(test);
};

/* another example
var One = artifacts.require('./One.sol');
var Two = artifacts.require('./Two.sol');

module.exports = async(deployer) => {
    let deployOne = await deployer.deploy(One);
    let deployTwo = await deployer.deploy(Two);
    contractTwo = await Two.deployed()
    let setAddress = await contractTwo.setAddress(
        One.address,
        { gas: 200000 }
    );
  };
*/
