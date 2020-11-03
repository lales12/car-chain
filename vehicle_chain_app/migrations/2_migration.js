module.exports = async (deployer, networks, accounts) => {
    const authorizeContract = artifacts.require("Authorizer");
    const baseContract = artifacts.require("BaseManager");
    const carAssetContract = artifacts.require("CarAsset");
    const carManagerContract = artifacts.require("CarManager");
    const iTVManagerConctract = artifacts.require("ITVManager");

    deployer.deploy(carAssetContract).then(async function (carAssetContract) {
		let carAssetContractAddress = carAssetContract.address;
		
		let authContract = await deployer.deploy(authorizeContract);

		let authorizeContractAddress = authContract.address;

		await deployer.deploy(baseContract, authorizeContractAddress, authorizeContractAddress);
		await deployer.deploy(carManagerContract, authorizeContractAddress, carAssetContractAddress);
		await deployer.deploy(iTVManagerConctract, authorizeContractAddress, carAssetContractAddress);
    });
};
