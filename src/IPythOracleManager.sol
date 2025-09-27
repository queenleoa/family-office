// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IPythOracleManager {
    function getETHPrice() external view returns (uint256);
    function getPYUSDPrice() external view returns (uint256);
    function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable;
    function getBothPrices() external view returns (uint256 ethPrice, uint256 pyusdPrice);
    function isPriceStale(bytes32 priceId) external view returns (bool);
}