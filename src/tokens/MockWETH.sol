// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockWETH is ERC20("Wrapped Ether", "WETH", 18) {
    function mint(address to, uint256 amt) external { _mint(to, amt); }
}
