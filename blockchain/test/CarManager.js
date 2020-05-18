const CarManager = artifacts.require("CarManager")

contract("CarManager", accounts => {
  const root = accounts[0];
  const brandAccount = accounts[1];
  const itvAccount = accounts[2];
  const userAccount = accounts[3];

  const licensePlate = "7610JBB";

  const permitTypes = {
    TWO_WHEEL: 0,
    THREE_WHEEL: 1,
    FOUR_WHEEL: 2,
    HEAVY: 3,
    SERVICE: 4,
    AGRICULTURE: 5
  };

  const itvStates = {
    INITIAL: 0,
    PASSED: 1,
    NOT_PASSED: 2,
    NEGATIVE: 3
  };

  let carManager
  beforeEach(async () => {
    carManager = await CarManager.new();
  });

  it("sets deploying account as root", async () => {
    const rootAccount = await carManager.root();
    assert.equal(rootAccount, root, "Error: invalid root account");
  });

  it("fails to add a new brand as non-root account", async () => {
    try {
      await carManager.addBrand(brandAccount, { from: userAccount });
    } catch (e) {
      assert.equal(e.reason, "Only root can manage brands", "Error: invalid error reason");
    }
  });

  it("adds a new brand as root account", async () => {
    await carManager.addBrand(brandAccount, { from: root });
    const brand = await carManager.brands(brandAccount);
    assert.isOk(brand, "failed to add brand");
  });

  it("fails to delete a brand from as non-root account", async () => {
    await carManager.addBrand(brandAccount, { from: root });
    try {
      await carManager.deleteBrand(brandAccount, { from: userAccount });
    } catch (e) {
      assert.equal(e.reason, "Only root can manage brands", "Error: invalid error reason");
    }
  });

  it("deletes a brand as root account", async () => {
    await carManager.addBrand(brandAccount, { from: root });
    await carManager.deleteBrand(brandAccount, { from: root });
    const brand = await carManager.brands(brandAccount);
    assert.isNotOk(brand, "failed to remove brand");
  });

  it("fails to add a new car as non-active brand", async () => {
    await carManager.addBrand(brandAccount, { from: root });
    try {
      await carManager.addCar(licensePlate, permitTypes.FOUR_WHEEL, { from: root });
    } catch (e) {
      assert.equal(e.reason, "Only active brand can add a new car", "Error: invalid error reason");
    }
  });

  it("adds a new car as an active brand", async () => {
    const carType = permitTypes.FOUR_WHEEL;
    await carManager.addBrand(brandAccount, { from: root });
    await carManager.addCar(licensePlate, carType, { from: brandAccount });
    const { ownerID, licensePlate: plate } = await carManager.getCar(licensePlate);
    assert.equal(ownerID, brandAccount, "Error: invalid ownerID");
    assert.equal(licensePlate, plate, "Error: invalid license plate");
  });

  it("adds a new ITV as root account", async () => {
    await carManager.addITV(brandAccount, { from: root });
    const ITV = await carManager.ITVAuthorities(brandAccount);
    assert.isOk(ITV, "Error: failed to add a new brand from root account");
  });

  it("deletes a ITV as root account", async () => {
    await carManager.addITV(brandAccount, { from: root });
    await carManager.deleteITV(brandAccount, { from: root });
    const ITV = await carManager.ITVAuthorities(brandAccount);
    assert.isNotOk(ITV, "Error: failed to delete brand from root account");
  });

  it("updates car ITV state", async () => {
    await carManager.addBrand(brandAccount, { from: root });
    await carManager.addCar(licensePlate, permitTypes.FOUR_WHEEL, { from: brandAccount });
    await carManager.addITV(itvAccount, { from: root });
    await carManager.updateITV(licensePlate, itvStates.PASSED, { from: itvAccount });
    const { itvState } = await carManager.getCar(licensePlate);
    assert.equal(itvStates.PASSED, itvState, "Error: carITVstate not updated");
  });
});