module.exports = async (deployer, networks, accounts) => {
    const authorizeContract = artifacts.require("Authorizer");
    const baseContract = artifacts.require("BaseManager");
    const carAssetContract = artifacts.require("CarAsset");
    const carManagerContract = artifacts.require("CarManager");
    const iTVManagerContract = artifacts.require("ITVManager");

    deployer.deploy(carAssetContract).then(async function (carAssetContract) {
		const carAssetContractAddress = carAssetContract.address;
		
		const authContract = await deployer.deploy(authorizeContract);

		const authorizeContractAddress = authContract.address;

		const baseCont = await deployer.deploy(baseContract, authorizeContractAddress, authorizeContractAddress);
		const carManagerCont = await deployer.deploy(carManagerContract, authorizeContractAddress, carAssetContractAddress);
    const ITVManagerCont = await deployer.deploy(iTVManagerContract, authorizeContractAddress, carAssetContractAddress);
    
    await carAssetContract.addManager(carManagerCont.address);
    });
};
