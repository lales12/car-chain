pragma solidity ^0.6.6;


contract Test {

    address public addr;
    
    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    /// signature methods.
    function splitSignature(bytes memory sig)
        public
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
    
    function recoverSigner(bytes memory sig)
        public
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        //bytes memory str = "1234qwer";
        bytes32 message = keccak256("1234qwer"); //prefixed(keccak256(str));
        
        return ecrecover(message, v, r, s);
    }
    
    function verifySigniture(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public returns(address recoveredAddress) {
        
        /*bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );*/
        
        //bytes32 digest = keccak256("1234qwer");
         // this recreates the message that was signed on the client
        // bytes memory str = "1234qwer";
        // bytes32 message = prefixed(keccak256(clearMsg));
        
        recoveredAddress = ecrecover(hash, v, r, s);

        addr = recoveredAddress;
    }

    function getAddress(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns(address recoveredAddress) {
        
        /*bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );*/
        
        //bytes32 digest = keccak256("1234qwer");
         // this recreates the message that was signed on the client
        // bytes memory str = "1234qwer";
        // bytes32 message = prefixed(keccak256(clearMsg));
        
        recoveredAddress = ecrecover(hash, v, r, s);

    }
    
    
}