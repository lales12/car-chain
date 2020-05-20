module.exports = deployer => {
  deployer.deploy(artifacts.require("Permissions"));
};