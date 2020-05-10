const CarManager = artifacts.require("CarManager")

contract("CarManager", accounts => {
  let carManager

  beforeEach(async () => {
    carManager = await CarManager.deployed();
  });

  it("sets deploying account as root", async () => {
    const rootAccount = await carManager.root.call();
    assert.equal(rootAccount, accounts[0], "Error: invalid root account");
  });

  it("fails to add a new brand as non-root account", async () => {
    try {
      await carManager.addBrand(accounts[1], { from: accounts[2] });
    } catch (e) {
      assert.equal(e.reason, "Only root can manage brands", "Error: invalid error reason");
    }
  });

  it("adds a new brand as root account", async () => {
    await carManager.addBrand(accounts[1], { from: accounts[0] });
    const brand = await carManager.brands.call(accounts[1]);
    assert.equal(brand, true, "Error: failed to add a new brand from root account");
  });

  it("fails to delete a brand from as non-root account", async () => {    
    await carManager.addBrand(accounts[1], { from: accounts[0] });
    try {
      await carManager.deleteBrand(accounts[1], { from: accounts[2] });
    } catch (e) {
      assert.equal(e.reason, "Only root can manage brands", "Error: invalid error reason");
    }
  });

  it("deletes a brand as root account", async () => {
    await carManager.addBrand(accounts[1], { from: accounts[0] });
    await carManager.deleteBrand(accounts[1], { from: accounts[0] });

    const brand = await carManager.brands.call(accounts[1]);
    assert.equal(brand, false, "Error: failed to delete brand from root account");
  });

  it("fails to add a new car as non-active brand", async () => {
    await carManager.addBrand(accounts[1], { from: accounts[0] });
    try {
      await carManager.addCar("7610JBB", 2, { from: accounts[0] });
    } catch (e) {
      assert.equal(e.reason, "Only active brand can add a new car", "Error: invalid error reason");
    }
  });

  it("adds a new car as an active brand", async () => {
    await carManager.addBrand(accounts[1], { from: accounts[0] });
    await carManager.addCar("7610JBB", 2, { from: accounts[1] });

    const { ownerID, licensePlate } = await carManager.getCar.call(1);
    assert.equal(ownerID, accounts[1], "Error: invalid ownerID");
    assert.equal(licensePlate, "7610JBB", "Error: invalid license plate");
  });

  it("Update Car Owner Type", async () => {
    await carManager.addBrand(accounts[1], { from: accounts[0] });
    await carManager.addCar("7610JBB", 2, { from: accounts[1] });
    const { carOwnerType } = await carManager.getCar.call(1);
    // console.log("oldtype = " + carOwnerType)
    const old_carOwnerType = carOwnerType;
    await carManager.updateCarOwenerType(1, 2, { from: accounts[1] });
    const response = await carManager.getCar.call(1);
    // console.log("newType = " + response.carOwnerType)
    assert.notDeepEqual(old_carOwnerType, response.carOwnerType, "Error: carOwnerType not updated");
  });
  
  it("adds a new ITV as root account", async () => {
    await carManager.addITV(accounts[1], { from: accounts[0] });
    const ITV = await carManager.auhtorizedITV.call(accounts[1]);
    assert.equal(ITV, true, "Error: failed to add a new brand from root account");
  });

  it("deletes a ITV as root account", async () => {
    await carManager.addITV(accounts[1], { from: accounts[0] });
    await carManager.deleteITV(accounts[1], { from: accounts[0] });

    const ITV = await carManager.auhtorizedITV.call(accounts[1]);
    assert.equal(ITV, false, "Error: failed to delete brand from root account");
  });

  it("Update Car ITV state", async () => {
    await carManager.addBrand(accounts[1], { from: accounts[0] });
    await carManager.addCar("7610JBB", 2, { from: accounts[1] });
    await carManager.addITV(accounts[2], { from: accounts[0] });
    const { carITVstate } = await carManager.getCar.call(1);
    const old_carITVstate = carITVstate;
    await carManager.updateITV(1, 1, { from: accounts[2] });
    const response = await carManager.getCar.call(1);
    assert.notDeepEqual(old_carITVstate, response.carITVstate, "Error: carITVstate not updated");
  });
});