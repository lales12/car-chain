module.exports = async (deployer, networks, accounts) => {
	const authorizeContract = artifacts.require("Authorizer");
	const baseContract = artifacts.require("BaseManager");
	const carManagerContract = artifacts.require("CarManager");
	const iTVManagerConctract = artifacts.require("ITVManager");

	let authorizeContractAddress;
	deployer.deploy(authorizeContract).then(function (authorizeContract) {
		authorizeContractAddress = authorizeContract.address;
		return deployer.deploy(baseContract, authorizeContractAddress).then(function () {
			return deployer.deploy(carManagerContract, authorizeContractAddress).then(function () {
				return deployer.deploy(iTVManagerConctract, authorizeContractAddress);
			});
		});
	});
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
