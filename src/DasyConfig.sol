// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {Vm} from "forge-std/Vm.sol";
import {strings} from "stringutils/strings.sol";

contract DasyConfig {
    using strings for *;

    /// @notice Initializes cheat codes in order to use ffi to compile Dasy contracts
    Vm public constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /// @notice Struct that represents a constant to be passed to the `-c` flag
    struct Constant {
        string key;
        string value;
    }

    /// @notice additional code to append to the source file
    string public code;

    /// @notice arguments to append to the bytecode
    bytes public args;

    /// @notice value to deploy the contract with
    uint256 public value;

    /// @notice whether to broadcast the deployment tx
    bool public should_broadcast;

    /// @notice constant overrides for the current compilation environment
    Constant[] public const_overrides;

    /// @notice sets the code to be appended to the source file
    function with_code(string memory code_) public returns (DasyConfig) {
        code = code_;
        return this;
    }

    /// @notice sets the arguments to be appended to the bytecode
    function with_args(bytes memory args_) public returns (DasyConfig) {
        args = args_;
        return this;
    }

    /// @notice sets the amount of wei to deploy the contract with
    function with_value(uint256 value_) public returns (DasyConfig) {
        value = value_;
        return this;
    }

    /// @notice sets a constant to a bytes memory value in the current compilation environment
    /// @dev The `value` string must contain a valid hex number that is <= 32 bytes
    ///      i.e. "0x01", "0xa57b", "0x0de0b6b3a7640000", etc. 
    function with_constant(
        string memory key,
        string memory value_
    ) public returns (DasyConfig) {
        const_overrides.push(Constant(key, value_));
        return this;
    }

    /// @notice sets a constant to an address value in the current compilation environment
    function with_addr_constant(
        string memory key,
        address value_
    ) public returns (DasyConfig) {
        const_overrides.push(Constant(key, bytesToString(abi.encodePacked(value_))));
        return this;
    }

    /// @notice sets a constant to a bytes32 value in the current compilation environment
    function with_bytes32_constant(
        string memory key,
        bytes32 value_
    ) public returns (DasyConfig) {
        const_overrides.push(Constant(key, bytesToString(abi.encodePacked(value_))));
        return this;
    }

    /// @notice sets a constant to a uint256 value in the current compilation environment
    function with_uint_constant(
        string memory key,
        uint256 value_
    ) public returns (DasyConfig) {
        const_overrides.push(Constant(key, bytesToString(abi.encodePacked(value_))));
        return this;
    }

    /// @notice sets whether to broadcast the deployment
    function set_broadcast(bool broadcast) public returns (DasyConfig) {
        should_broadcast = broadcast;
        return this;
    }

    /// @notice Checks for dasyc binary conflicts
    function binary_check() public {
        string[] memory bincheck = new string[](1);
        bincheck[0] = "./lib/foundry-dasy/scripts/binary_check.sh";
        bytes memory retData = vm.ffi(bincheck);
        bytes8 first_bytes = retData[0];
        bool decoded = first_bytes == bytes8(hex"01");
        require(
            decoded,
            "Invalid dasyc binary. Run `curl -L get.dasy.sh | bash` and `dasyup` to fix."
        );
    }

    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        string memory result;
        for (uint256 j = 0; j < x.length; j++) {
            result = string.concat(
                result, string(abi.encodePacked(uint8(x[j]) % 26 + 97))
            );
        }
        return result;
    }

    function bytesToString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    /// @notice Deploy the Contract
    function deploy(string memory file) public payable returns (address) {

        string[] memory cmds = new string[](2);
        cmds[0] = "dasy";
        cmds[1] = string.concat("src/", file, ".dasy");

        /// @notice compile the Dasy contract and return the bytecode
        bytes memory bytecode = vm.ffi(cmds);
        bytes memory concatenated = bytes.concat(bytecode, args);

        /// @notice deploy the bytecode with the create instruction
        address deployedAddress;
        if (should_broadcast) vm.broadcast();
        assembly {
            let val := sload(value.slot)
            deployedAddress := create(val, add(concatenated, 0x20), mload(concatenated))
        }

        /// @notice check that the deployment was successful
        require(
            deployedAddress != address(0), "HuffDeployer could not deploy contract"
        );

        /// @notice return the address that the contract was deployed to
        return deployedAddress;
    }
}
