const CarTracker = artifacts.require("CarTracker");
const Auth = artifacts.require("Permissions");

contract("CarTracker", async accounts => {
  const [owner, carManager, unauthorizedAccount, dealership, itvAuthority] = accounts;

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

  const carStates = {
    SHIPPED: 0,
    FOR_SALE: 1,
    PROCESSING_SALE: 2,
    SOLD: 3,
    PROCESSING_REGISTER: 4,
    REGISTERED: 5
  };

  const itvStates = {
    PASSED: 0,
    NOT_PASSED: 1,
    NEGATIVE: 2
  };

  const errors = {
    unauthorized: "Unauthorized"
  };

  const lastInspectionDefaultValue = 0;

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
    await auth.addPermission(carTracker.address, methods.addCar, carManager, { from: owner });
    await carTracker.addCar(carID, licensePlate, carTypes.FOUR_WHEEL, { from: carManager });
    const { ID, ownerID, licensePlate: licensePlateReturned, carType, carState, itvState, lastInspection } = await carTracker.getCar(carID);
    const carIDHash = web3.utils.keccak256(carID);
    assert.equal(ID, carIDHash);
    assert.equal(ownerID, carManager);
    assert.equal(licensePlateReturned, licensePlate);
    assert.equal(carType, carTypes.FOUR_WHEEL);
    assert.equal(carState, carStates.FOR_SALE);
    assert.equal(itvState, itvStates.PASSED);
    assert.equal(lastInspection, lastInspectionDefaultValue);
  });

  it("fails to update car state from unauthorized account", async () => {
    try {
      await auth.addPermission(carTracker.address, methods.addCar, carManager, { from: owner });
      await carTracker.addCar(carID, licensePlate, carTypes.FOUR_WHEEL, { from: carManager });
      await auth.addPermission(carTracker.address, methods.updateCarState, dealership, { from: owner });
      await carTracker.updateCarState(carID, carStates.SOLD, { from: unauthorizedAccount });
    } catch (e) {
      assert.equal(e.reason, errors.unauthorized, "error: unexpected error on update car state");
    }
  });

  it("updates car state from authorized account", async () => {
    await auth.addPermission(carTracker.address, methods.addCar, carManager, { from: owner });
    await carTracker.addCar(carID, licensePlate, carTypes.FOUR_WHEEL, { from: carManager });
    await auth.addPermission(carTracker.address, methods.updateCarState, dealership, { from: owner });
    await carTracker.updateCarState(carID, carStates.SOLD, { from: dealership });
    const { carState } = await carTracker.getCar(carID);
    assert.equal(carState, carStates.SOLD, "error: wrong car state after update");
  });

  it("fails to update itv state from unauthorized account", async () => {
    try {
      await auth.addPermission(carTracker.address, methods.addCar, carManager, { from: owner });
      await carTracker.addCar(carID, licensePlate, carTypes.FOUR_WHEEL, { from: carManager });
      await auth.addPermission(carTracker.address, methods.updateITV, itvAuthority, { from: owner });
      await carTracker.updateITV(carID, itvStates.NOT_PASSED, { from: unauthorizedAccount });
    } catch (e) {
      assert.equal(e.reason, errors.unauthorized, "error: unexpected error on update itv state");
    }
  });

  it("updates itv state from authorized account", async () => {
    await auth.addPermission(carTracker.address, methods.addCar, carManager, { from: owner });
    await carTracker.addCar(carID, licensePlate, carTypes.FOUR_WHEEL, { from: carManager });
    await auth.addPermission(carTracker.address, methods.updateITV, itvAuthority, { from: owner });
    await carTracker.updateITV(carID, itvStates.NOT_PASSED, { from: itvAuthority });
    const { itvState } = await carTracker.getCar(carID);
    assert.equal(itvState, itvStates.NOT_PASSED, "error: wrong itv state after update");
  });
});
