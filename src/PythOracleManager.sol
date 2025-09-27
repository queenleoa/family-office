// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

interface IPythOracleManager {
    function getETHPrice() external view returns (uint256);
    function getPYUSDPrice() external view returns (uint256);
    function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable;
}

contract PythOracleManager is IPythOracleManager {
    IPyth public immutable pythOracle;
    
    // Price feed IDs (these are examples - use actual Pyth price feed IDs)
    bytes32 public constant ETH_USD_PRICE_FEED = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    bytes32 public constant PYUSD_USD_PRICE_FEED = 0x0000000000000000000000000000000000000000000000000000000000000001; // Placeholder
    
    uint256 public constant PRICE_STALENESS_THRESHOLD = 60; // 60 seconds
    
    event PricesUpdated(uint256 ethPrice, uint256 pyusdPrice, uint256 timestamp);
    
    constructor(address _pythOracle) {
        pythOracle = IPyth(_pythOracle);
    }
    
    /// @notice Get ETH price in USD with 18 decimals
    function getETHPrice() external view override returns (uint256) {
        return _getPriceUnsafe(ETH_USD_PRICE_FEED);
    }
    
    /// @notice Get PYUSD price (should be ~$1)
    function getPYUSDPrice() external pure override returns (uint256) {
        // PYUSD is pegged to USD, return $1 with 18 decimals
        // In production, would fetch actual price for deviations
        return 1e18;
    }
    
    /// @notice Update price feeds with signed price data from Pyth
    function updatePriceFeeds(bytes[] calldata priceUpdateData) external payable override {
        uint fee = pythOracle.getUpdateFee(priceUpdateData);
        require(msg.value >= fee, "Insufficient fee");
        
        pythOracle.updatePriceFeeds{value: fee}(priceUpdateData);
        
        emit PricesUpdated(
            _getPriceUnsafe(ETH_USD_PRICE_FEED),
            1e18, // PYUSD stable at $1
            block.timestamp
        );
        
        // Refund excess fee
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }
    
    /// @notice Get price from Pyth oracle (for hackathon, using unsafe for simplicity)
    function _getPriceUnsafe(bytes32 priceId) internal view returns (uint256) {
        PythStructs.Price memory price = pythOracle.getPriceUnsafe(priceId);
        
        // Convert price to 18 decimals
        uint256 priceValue = uint256(uint64(price.price));
        
        if (price.expo >= 0) {
            return priceValue * (10 ** uint256(uint32(price.expo))) * 1e18;
        } else {
            uint256 divisor = 10 ** uint256(uint32(-price.expo));
            return (priceValue * 1e18) / divisor;
        }
    }
    
    /// @notice Check if price data is stale
    function isPriceStale(bytes32 priceId) external view returns (bool) {
        PythStructs.Price memory price = pythOracle.getPriceUnsafe(priceId);
        return (block.timestamp - price.publishTime) > PRICE_STALENESS_THRESHOLD;
    }
    
    /// @notice Get both prices in one call for gas efficiency
    function getBothPrices() external view returns (uint256 ethPrice, uint256 pyusdPrice) {
        ethPrice = _getPriceUnsafe(ETH_USD_PRICE_FEED);
        pyusdPrice = 1e18; // PYUSD stable
    }
}