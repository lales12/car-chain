const EnjoyPass = artifacts.require("SimpleStorage");

module.exports = function(deployer, network, accounts) {
    deployer.deploy(EnjoyPass)
        .then(async (contract) => {
            await contract.addRoot(accounts[1], {from: accounts[0]});
            await contract.addDoctor(accounts[2], {from: accounts[1]});
        });
};
