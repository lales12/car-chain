const BaseManager = artifacts.require("BaseManager");

contract("BaseManager", (accounts) => {
    let baseManagerContract;
    const authorizerAddress = "0x001d3f1ef827552ae1114027bd3ecf1f086ba0f9";
    const assetAddress = "0x001d3f1ef827552ae1114027bd3ecf1f087ba0f9";
    const owner = accounts[0];

    beforeEach(async () => {
        baseManagerContract = await BaseManager.new(authorizerAddress, assetAddress);
    });

    it("sets deploying account as root", async () => {
        const rootAccount = await baseManagerContract.owner();
        assert.equal(rootAccount, owner, "Error: invalid root account");
    });
});
