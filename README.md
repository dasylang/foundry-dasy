# Foundry x Dasy

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A [foundry](https://github.com/foundry-rs/foundry) library for working with [dasy](https://github.com/dasylang/dasy) contracts. Take a look at [z80's skunkworks](https://github.com/z80dev/skunkworks) to see an example project that uses this library.


## Installing

First, install the [dasy compiler](https://github.com/dasylang/dasy) by running:
```
pipx install dasy
```

Then, install this library with [forge](https://github.com/foundry-rs/foundry):
```
forge install dasylang/foundry-dasy
```


## Usage

The HuffDeployer is a Solidity library that takes a filename and deploys the corresponding Huff contract, returning the address that the bytecode was deployed to. To use it, simply import it into your file by doing:

```js
import {DasyDeployer} from "foundry-dasy/DasyDeployer.sol";
```

To compile contracts, you can use `DasyDeployer.deploy(string fileName)`, which takes in a single string representing the filename's path relative to the `src` directory. Note that the file ending, i.e. `.dasy`, must be omitted.
Here is an example deployment (where the contract is located in [`src/test/contracts/Number.dasy`](./src/test/contracts/Number.dasy)):

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import {DasyDeployer} from "foundry-dasy/DasyDeployer";

interface Number {
  function setNumber(uint256) external;
  function getNumber() external returns (uint256);
}

contract DasyDeployerExample {
  function deploy() public {
    // Deploy a new instance of src/test/contracts/Number.dasy
    address addr = DasyDeployer.deploy("test/contracts/Number");

    // To call a function on the deployed contract, create an interface and wrap the address like so
    Number number = Number(addr);
  }
}
```

To deploy a Dasy contract with constructor arguments, you can _chain_ commands onto the DasyDeployer.

For example, to deploy the contract [`src/test/contracts/Constructor.dasy`](src/test/contracts/Constructor.dasy) with arguments `(uint256(0x420), uint256(0x420))`, you are encouraged to follow the logic defined in the `deploy` function of the `DasyDeployerArguments` contract below.

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;

import {DasyDeployer} from "foundry-dasy/DasyDeployer";

interface Constructor {
  function getArgOne() external returns (address);
  function getArgTwo() external returns (uint256);
}

contract DasyDeployerArguments {
  function deploy() public {
    // Deploy the contract with arguments
    address addr = DasyDeployer
      .config()
      .with_args(bytes.concat(abi.encode(uint256(0x420)), abi.encode(uint256(0x420))))
      .deploy("test/contracts/Constructor");

    // To call a function on the deployed contract, create an interface and wrap the address
    Constructor construct = Constructor(addr);

    // Validate we deployed the Constructor with the correct arguments
    assert(construct.getArgOne() == address(0x420));
    assert(construct.getArgTwo() == uint256(0x420));
  }
}
```
