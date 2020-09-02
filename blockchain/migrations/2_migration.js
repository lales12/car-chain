module.exports = async (deployer, networks, accounts) => {
    const permissionsContract = artifacts.require("Authorizer");
    const carManagerContract = artifacts.require("CarManager");
    const baseManagerConctract = artifacts.require("BaseManager");

    // deployer.deploy(permissionsContract).then(function (permissionsInstance) {
    //     return deployer.deploy(carManagerContract, permissionsInstance.address);
    // });
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
