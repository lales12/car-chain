module.exports = deployer => {
  deployer.deploy(artifacts.require("CarInterface"));
};