const Authorizer = artifacts.require("Authorizer");

contract("Authorizer", async (accounts) => {
    const owner = accounts[0];
    const hacker = accounts[1];

    // add/remove permissions test variables
    const _contract = accounts[2];
    const _method = "addBrandaddress";
    const _to = accounts[3];

    const errors = {
        ONLY_OWNER: "Only owner can manage permissions",
    };

    const events = {
        PERMISSION_ADDED: "PermissionAdded",
        PERMISSION_REMOVED: "PermissionRemoved",
    };

    let contract;
    beforeEach(async () => {
        try {
            contract = await Authorizer.new({ from: owner });
        } catch (e) {
            assert.fail("error: contract deploy failed");
        }
    });

    it("deploys the contract correctly", async () => {
        assert.isOk(contract, "error: contract deploy failed");
        const contractOwner = await contract.owner();
        assert.equal(contractOwner, owner, "error: failed to set the owner on deploy");
    });

    it("fails to add permission as non-owner account", async () => {
        try {
            await contract.addPermission(_contract, _method, _to, { from: hacker });
            assert.fail("error: added permission as non-owner");
        } catch (e) {
            assert.equal(e.reason, errors.ONLY_OWNER, "error: unexpected error when adding permission as non-owner");
        }
    });

    it("allows owner to add a permission", async () => {
        try {
            await contract.addPermission(_contract, _method, _to, { from: owner });
            const methodHash = await web3.utils.soliditySha3(_method);

            const permission = await contract.permissions(_contract, methodHash, _to);
            assert.isOk(permission, "error: failed to add permission as owner");
        } catch (e) {
            assert.fail("error: failed to add permission as owner");
        }
    });

    it("emits a 'PermissionAdded' event correctly", async () => {
        const {
            receipt: {
                logs: [eventObj],
            },
        } = await contract.addPermission(_contract, _method, _to, { from: owner });
        const {
            event: eventName,
            args: { _contract: contractResult, _method: methodResult, _to: toResult },
        } = eventObj;

        assert.equal(eventName, events.PERMISSION_ADDED, "error: wrong event name");
        assert.equal(_contract, contractResult, "error: wrong event contract");
        assert.equal(_method, methodResult, "error: wrong event method");
        assert.equal(_to, toResult, "error: wrong event 'to' address");
    });

    it("fails to remove permission as non-owner account", async () => {
        try {
            await contract.removePermission(_contract, _method, _to, { from: hacker });
            assert.fail("error: removed permission as non-owner");
        } catch (e) {
            assert.equal(e.reason, errors.ONLY_OWNER, "error: unexpected error when removing permission as non-owner");
        }
    });

    it("allows owner to remove a permission", async () => {
        try {
            await contract.addPermission(_contract, _method, _to, { from: owner });

            await contract.removePermission(_contract, _method, _to, { from: owner });

            const permission = await contract.requestAccess(_contract, _method, _to);
            assert.isNotOk(permission, "error: failed to remove permission as owner");
        } catch (e) {
            console.log(e.message)
            assert.fail("error: failed to remove permission as owner");
        }
    });

    it("emits a 'PermissionRemoved' event correctly", async () => {
        await contract.addPermission(_contract, _method, _to, { from: owner });

        const {
            receipt: {
                logs: [eventObj],
            },
        } = await contract.removePermission(_contract, _method, _to, { from: owner });
        const {
            event: eventName,
            args: { _contract: contractResult, _method: methodResult, _to: toResult },
        } = eventObj;

        assert.equal(eventName, events.PERMISSION_REMOVED, "error: wrong event name");
        assert.equal(_contract, contractResult, "error: wrong event contract");
        assert.equal(_method, methodResult, "error: wrong event method");
        assert.equal(_to, toResult, "error: wrong event 'to' address");
    });

    it("retrieves permissions correctly", async () => {
        await contract.addPermission(_contract, _method, _to, { from: owner });
        const access = await contract.requestAccess(_contract, _method, _to);
        assert.isOk(access, "error: failed to retrieve permissions");
    });
});
