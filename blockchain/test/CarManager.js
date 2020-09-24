const CarManager = artifacts.require("CarManager");
const Authorizer = artifacts.require("Authorizer");
const CarAsset = artifacts.require("CarAsset");

contract("CarManager", (accounts) => {
    const root = accounts[0];
    const brandAccount = accounts[1];
    const itvAccount = accounts[2];
    const userAccount = accounts[3];

    const ADD_CAR_METHOD = "addCar(bytes,string,uint256)";

    const carId = "1G1YY25R695700001";
    const carIdHash = "asdfasdfasdf";
    const licensePlate = "7610JBB";

    const carTypes = {
        TWO_WHEEL: 0,
        THREE_WHEEL: 1,
        FOUR_WHEEL: 2,
        HEAVY: 3,
        SERVICE: 4,
        AGRICULTURE: 5,
    };

    const itvStates = {
        PASSED: 0,
        NOT_PASSED: 1,
        NEGATIVE: 2,
    };

    let carManager;
    let carAsset;
    let authorizer;

    beforeEach(async () => {
        authorizer = await Authorizer.new();
        carAsset = await CarAsset.new();
        carManager = await CarManager.new(authorizer.address, carAsset.address);

        authorizer.addPermission(carManager.address, ADD_CAR_METHOD, brandAccount);
    });

    it("sets deploying account as root", async () => {
        const rootAccount = await carManager.owner();
        assert.equal(rootAccount, root, "Error: invalid root account");
    });

    it("Add new car from brand account", async () => {
        await carManager.addCar(carId, carIdHash, licensePlate, carTypes.THREE_WHEEL, { from: brandAccount });
    });

    it("Add new car from invalid account", async () => {
        try {
            await carManager.addCar(carId, carIdHash, licensePlate, carTypes.THREE_WHEEL, { from: userAccount });
            assert.fail("This must fail");
        } catch (error) {
            assert.include(error.message, "transaction: revert Unauthorized");
        }
    });
});
