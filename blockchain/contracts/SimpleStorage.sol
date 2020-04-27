pragma solidity<0.6.0;

contract SimpleStorage {
    uint[] store;

    constructor (uint initialValue) public {
        store.push(initialValue);
    }

    function storeValue(uint value) public {
        store.push(value);
    }

    function getValue(uint index)
        public
        view
        returns (uint valaue)
    {
        return store[index];
    }
}
