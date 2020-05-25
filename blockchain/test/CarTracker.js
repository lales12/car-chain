const CarTracker = artifacts.require("CarTracker");
const Auth = artifacts.require("Permissions");

contract("CarTracker", async accounts => {
  const owner = accounts[0];
  const carManager = accounts[1];
  const method = "addCar(bytes,string,uint256)";

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

  it("allows carManager to add a new car", async () => {
    try {
      const { receipt: { logs: [event] } } = await auth.addPermission(carTracker.address, method, carManager, { from: owner });
      const { event: eventName, args: { _contract, _method, _to } } = event;
      // const methodHash = await web3.utils.soliditySha3(method);
      // const authorized = await auth.permissions(carTracker.address, methodHash, carManager);
      // console.log({authorized});
      // reverts on unauthorized error when requesting access to permissions contract event though everything looks fine
      await carTracker.addCar(carID, licensePlate, carTypes.FOUR_WHEEL, { from: carManager });
    } catch (e) {
      console.log({ e });
      assert.fail("error: failed to add a new car");
    }
  });
});
