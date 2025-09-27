// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockPYUSD is ERC20("PayPal USD", "PYUSD", 6) {
    function mint(address to, uint256 amt) external { _mint(to, amt); }
}
