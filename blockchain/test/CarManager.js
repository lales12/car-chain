const CarManager = artifacts.require("CarManager");
const Authorizer = artifacts.require("Authorizer");
const CarAsset = artifacts.require("CarAsset");

const CAR_ADDED_EVENT = 'CarAdded';


const REVERT_ERROR = 'Reason given: Unauthorized';

contract("CarManager", (accounts) => {
    const root = accounts[0];
    const manufacturerAddress = accounts[1];
    const manufacturer2Address = accounts[2]
    const brandAddress = accounts[3];
    const brand2Address = accounts[4];
    const userAddress = accounts[5];

    const carAccount = web3.eth.accounts.create();
    const carAddress = carAccount.address;

    const carId = "1G1YY25R695700001";
    const carIdHashSigned = carAccount.sign(carId);
    const carIdHash = carIdHashSigned.messageHash;
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

    let carManagerContract;
    let carAssetContract;
    let authorizerContract;

    let CREATE_CAR_METHOD;
    let SELL_CAR_METHOD;
    let DELIVER_CAR_METHOD;
    let REGISTER_CAR_METHOD;

    before(async () => {
        authorizerContract = await Authorizer.new();
        carAssetContract = await CarAsset.new();
        carManagerContract = await CarManager.new(authorizerContract.address, carAssetContract.address);
        
        CREATE_CAR_METHOD = await carManagerContract.CREATE_CAR_METHOD();
        SELL_CAR_METHOD = await carManagerContract.SELL_CAR_METHOD();
        DELIVER_CAR_METHOD = await carManagerContract.DELIVER_CAR_METHOD();
        REGISTER_CAR_METHOD = await carManagerContract.REGISTER_CAR_METHOD();
    });

    beforeEach(async () => {
        authorizerContract = await Authorizer.new();
        carAssetContract = await CarAsset.new();
        carManagerContract = await CarManager.new(
            authorizerContract.address, 
            carAssetContract.address
        );

        await carAssetContract.addManager(carManagerContract.address, {from: root})

        authorizerContract.addPermission(
            carManagerContract.address, 
            CREATE_CAR_METHOD, 
            manufacturerAddress
        );

        authorizerContract.addPermission(
            carManagerContract.address, 
            DELIVER_CAR_METHOD, 
            manufacturerAddress
        );

        authorizerContract.addPermission(
            carManagerContract.address,
            REGISTER_CAR_METHOD,
            brandAddress
        );

        authorizerContract.addPermission(
            carManagerContract.address,
            SELL_CAR_METHOD,
            brandAddress
        );

        authorizerContract.addPermission(
            carManagerContract.address,
            SELL_CAR_METHOD,
            brandAddress
        );

        authorizerContract.addPermission(
            carManagerContract.address,
            SELL_CAR_METHOD,
            brand2Address
        );
    });

    it("sets deploying account as root", async () => {
        const rootAccount = await carManagerContract.owner();

        assert.equal(rootAccount, root, "Error: invalid root account");
    });

    it("Add new car from manufacturer account", async () => {
        await createCar(manufacturerAddress)

        const events = await carManagerContract.getPastEvents(
            'allEvents', 
            {
                filter: {
                    carAddress: carAddress
                },
                fromBlock: 0, 
                toBlock: "latest" 
            }
        );

        const carAddedEvent = events[0];
        
        assert.equal(carAddedEvent.event, CAR_ADDED_EVENT);
        assert.equal(carAddedEvent.returnValues.carAddress, carAddress);
    });

    it("Add new car from invalid account", async () => {
        try {
            await createCar(userAddress);

            assert.fail('This must fail');
        } catch (error) {
            assert.include(error.message, REVERT_ERROR);
        }

    });

    it("Add new car from brand account, this must throw error", async () => {
        try {
            await createCar(brandAddress)
        } catch {
            assert.ok('This account cant perform this action');
            return;
        }

        assert.fail('The account allow create car');
    });

    it("Retrieve created car data", async() => {
        await createCar(manufacturerAddress);

        const deployedCarAddress = await carAssetContract.getCarAddress(carIdHash);
        const deployedCarHash = await carAssetContract.getCarToken(carAddress);
        const deployedCarOwnerAddress = await carAssetContract.ownerOf(carIdHash);
        
        assert.equal(deployedCarAddress, carAddress);
        assert.equal(BigInt(deployedCarHash), carIdHash);
        assert.equal(deployedCarOwnerAddress, manufacturerAddress);

    })

    it('Deliver car from manufacturer account', async () => {
        await createCar(manufacturerAddress);

        await carManagerContract.deliverCar(
            carAddress,
            {
                from: manufacturerAddress
            }
        );

        await carAssetContract.transferFrom(
            manufacturerAddress,
            brandAddress,
            carIdHash,
            {
                from: manufacturerAddress
            }
        );

        const newOwner = await carAssetContract.ownerOf(carIdHash);

        assert.equal(newOwner, brandAddress);
    });

    it('Deliver car from no owner asset brand account', async () => {
        let cantSellCar = false;
        let cantTransferCar = false;

        await createCar(manufacturerAddress);

        try {
            await carManagerContract.deliverCar(
                carAddress,
                {
                    from: manufacturer2Address
                }
            );
    
        } catch {
            cantSellCar = true;
        }

        try {
            await carAssetContract.transferFrom(
                brandAddress,
                userAddress,
                carIdHash,
                {
                    from: manufacturer2Address
                }
            );
        } catch  {
            cantTransferCar = true;
        }

        const newOwner = await carAssetContract.ownerOf(carIdHash);

        assert.isTrue(cantSellCar);
        assert.isTrue(cantTransferCar);
        assert.equal(manufacturerAddress, newOwner);
    });

    it('Register car from the brand account', async () => {
        await createCarAndDeliver(manufacturerAddress, brandAddress);

        await carManagerContract.sellCar(
            carAddress, {
                from: brandAddress
            }
        );

        await carManagerContract.registerCar(
            carAddress,
            licensePlate,
            {
                from: brandAddress
            }
        );

        const newOwner = await carAssetContract.ownerOf(carIdHash);
        const carData = await carManagerContract.getCar(carAddress);

        assert.equal(brandAddress, newOwner);
        assert.equal(carData.licensePlate, licensePlate);
    });
    // it('Sell car from non created brand account', async () => {
    //     await createCar(brandAddress);

    //     try {
    //         // The buyer must approve the transaction token
    //         await carAssetContract.approve(
    //             carManagerContract.address,
    //             carIdHash,
    //             {
    //                 from: brand2Address
    //             }
    //         );

    //         await carManagerContract.sellCar(
    //             carAddress,
    //             userAddress,
    //             {
    //                 from: brand2Address
    //             }
    //         );
    //     } catch(error) {
    //         assert.ok('This action must fail');

    //         return;
    //     }

    //     assert.fail('This account cant perform this action');
    // });

    // it('Sell accepted transfer car from non created brand account', async () => {
    //     await createCar(brandAddress);

    //     try {
    //         // The buyer must approve the transaction token
    //         await carAssetContract.approve(
    //             carManagerContract.address,
    //             carIdHash,
    //             {
    //                 from: brandAddress
    //             }
    //         );
    //     } catch(error) {
    //         assert.ok('This action must fail');

    //         return;
    //     }

    //     assert.fail('This account cant perform this action');
    // });


    async function createCar(from) {
        await carManagerContract.createCar(
            carIdHash, 
            carIdHashSigned.signature, 
            carTypes.THREE_WHEEL, 
            {
                from,
            }
        );
    }

    async function createCarAndDeliver(manufacturer, seller) {
        await carManagerContract.createCar(
            carIdHash, 
            carIdHashSigned.signature, 
            carTypes.THREE_WHEEL, 
            {
                from: manufacturer
            }
        );

        await carManagerContract.deliverCar(
            carAddress,
            {
                from: manufacturer
            }
        );

        await carAssetContract.transferFrom(
            manufacturer,
            seller,
            carIdHash,
            {
                from: manufacturer
            }
        );

    }
});
