module.exports = (deployer, networks, accounts) => {
	const permissionsContract = artifacts.require("Permissions");
	const carTrackerContract = artifacts.require("CarTracker");
	const carManagerContract = artifacts.require("CarManager");

	deployer.deploy(permissionsContract).then((permissionsInstance) => {
		deployer.deploy(carTrackerContract, permissionsInstance.address);
		deployer.deploy(carManagerContract);
	});
};
