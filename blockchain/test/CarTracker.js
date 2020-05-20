const CarTracker = artifacts.require("CarTracker");

contract("CarTracker", async () => {

  let contract;
  beforeEach(async () => {
    try {
      contract = await CarTracker.new();
    } catch (e) {
      assert.fail("error: contract deploy failed");
    }
  });

  it("deploys the contract correctly", async () => {
    assert.isOk(contract, "error: contract deploy failed");
  });
});