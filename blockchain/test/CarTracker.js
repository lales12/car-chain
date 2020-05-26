const CarTracker = artifacts.require("CarTracker");
const Auth = artifacts.require("Permissions");

contract("CarTracker", async accounts => {
  const owner = accounts[0];
  const carManager = accounts[1];
  const unauthorizedAccount = accounts[2];

  const methods = {
    addCar: "addCar(bytes,string,uint256)",
    updateCarState: "updateCarState(bytes,uint256)",
    updateITV: "updateITV(bytes,uint256)"
  };

  const carID = web3.utils.asciiToHex("1G1YY25R695700001");
  const licensePlate = "7610JBB";

  const carTypes = {
    TWO_WHEEL: 0,
    THREE_WHEEL: 1,
    FOUR_WHEEL: 2,
    HEAVY: 3,
    SERVICE: 4,
    AGRICULTURE: 5
  };

  const itvStates = {
    PASSED: 0,
    NOT_PASSED: 1,
    NEGATIVE: 2
  };

  const errors = {
    unauthorized: "Unauthorized"
  };

  let carTracker;
  let auth;
  beforeEach(async () => {
    try {
      auth = await Auth.new({ from: owner });
      carTracker = await CarTracker.new(auth.address);
    } catch (e) {
      assert.fail("error: contracts failed to deploy");
    }
  });

  it("deploys the carTracker contract correctly", async () => {
    assert.isOk(carTracker, "error: carTracker contract deploy failed");
  });

  it("deploys the auth contract correctly", async () => {
    assert.isOk(auth, "error: auth contract deploy failed");
    const authOwner = await auth.owner();
    assert.equal(owner, authOwner, "error: failed to assign correct contract owner");
  });

  it("fails to add a car from unauthorized account", async () => {
    try {
      await auth.addPermission(carTracker.address, methods.addCar, carManager, { from: owner });
      await carTracker.addCar(carID, licensePlate, carTypes.THREE_WHEEL, { from: unauthorizedAccount });
    } catch (e) {
      assert.equal(e.reason, errors.unauthorized, "error: unexpected error on add car");
    }
  });

  it("allows carManager to add a new car", async () => {
    try {
      await auth.addPermission(carTracker.address, methods.addCar, carManager, { from: owner });
      await carTracker.addCar(carID, licensePlate, carTypes.FOUR_WHEEL, { from: carManager });
    } catch (e) {
      assert.fail("error: failed to add a new car");
    }
  });

});
