const CarManager = artifacts.require("CarManager")

contract("CarManager", accounts => {

  it("sets deploying account as root", async () => {
    const carManager = await CarManager.deployed();

    const rootAccount = await carManager.root.call();
    assert.equal(rootAccount, accounts[0], "Error: invalid root account");
  });

  it("fails to add a new brand as non-root account", async () => {
    const carManager = await CarManager.deployed();

    try {
      await carManager.addBrand(accounts[1], { from: accounts[2] });
    } catch (e) {
      assert.equal(e.reason, "Only root can manage brands", "Error: invalid error reason");
    }
  });

  it("adds a new brand as root account", async () => {
    const carManager = await CarManager.deployed();

    await carManager.addBrand(accounts[1], { from: accounts[0] });
    const brand = await carManager.brands.call(accounts[1]);
    assert.equal(brand, true, "Error: failed to add a new brand from root account");
  });

  it("fails to delete a brand from as non-root account", async () => {
    const carManager = await CarManager.deployed();
    await carManager.addBrand(accounts[1], { from: accounts[0] });

    try {
      await carManager.deleteBrand(accounts[1], { from: accounts[2] });
    } catch (e) {
      assert.equal(e.reason, "Only root can manage brands", "Error: invalid error reason");
    }
  });

  it("deletes a brand as root account", async () => {
    const carManager = await CarManager.deployed();

    await carManager.addBrand(accounts[1], { from: accounts[0] });
    await carManager.deleteBrand(accounts[1], { from: accounts[0] });

    const brand = await carManager.brands.call(accounts[1]);
    assert.equal(brand, false, "Error: failed to delete brand from root account");
  });

  it("fails to add a new car as non-active brand", async () => {
    const carManager = await CarManager.deployed();

    await carManager.addBrand(accounts[1], { from: accounts[0] });
    try {
      await carManager.addCar("7610JBB", { from: accounts[0] });
    } catch (e) {
      assert.equal(e.reason, "Only active brand can add a new car", "Error: invalid error reason");
    }
  });

  it("adds a new car as an active brand", async () => {
    const carManager = await CarManager.deployed();

    await carManager.addBrand(accounts[1], { from: accounts[0] });
    await carManager.addCar("7610JBB", { from: accounts[1] });

    const { ownerID, licensePlate } = await carManager.getCar.call(1);
    assert.equal(ownerID, accounts[1], "Error: invalid ownerID");
    assert.equal(licensePlate, "7610JBB", "Error: invalid license plate");
  });
});