module.exports = async (deployer, networks, accounts) => {
    const authorizeContract = artifacts.require("Authorizer");
    const baseContract = artifacts.require("BaseManager");
    const carAssetContract = artifacts.require("CarAsset");
    const carManagerContract = artifacts.require("CarManager");
    const iTVManagerConctract = artifacts.require("ITVManager");

    deployer.deploy(carAssetContract).then(function (carAssetContract) {
        let carAssetContractAddress = carAssetContract.address;
        deployer.deploy(authorizeContract).then(function (authorizeContract) {
            let authorizeContractAddress = authorizeContract.address;

            deployer.deploy(baseContract, authorizeContractAddress, authorizeContractAddress);
            deployer.deploy(carManagerContract, authorizeContractAddress, carAssetContractAddress);
            deployer.deploy(iTVManagerConctract, authorizeContractAddress, carAssetContractAddress);
        });
    });
};
