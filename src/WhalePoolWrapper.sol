// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Pyth Oracle interface
interface IPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
    }
    
    function updatePriceFeeds(bytes[] calldata updateData) external payable;
    function getPriceUnsafe(bytes32 id) external view returns (Price memory);
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint);
}

contract WhalePoolWrapper is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Pyth oracle and price feeds
    IPyth public constant PYTH = IPyth(0xDd24F84d36BF92C65F92307595335bdFab5Bbd21); // Sepolia Pyth
    bytes32 public constant ETH_USD_PRICE_FEED = 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    bytes32 public constant PYUSD_USD_PRICE_FEED = 0x5b245b5906625fb27d8d848d27bfcaf72b8a5f5ea7e99e284665c6c4c4a04c9f; // Mock for demo
    
    // Family deposits tracking
    struct FamilyPosition {
        uint256 pyusdDeposited;
        uint256 sharePercentage; // in basis points (10000 = 100%)
        uint256 lastRebalancePrice;
    }
    
    mapping(address => FamilyPosition) public familyPositions;
    address[] public families;
    uint256 public totalPyusdDeposited;
    
    // Pool references
    PoolKey public targetPool; // The whale pool we're joining
    uint256 public wrapperPositionId; // Our NFT position in the whale pool
    
    // Constants
    uint256 public constant REBALANCE_THRESHOLD = 500; // 5% price movement triggers rebalance
    address public constant PYUSD = 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9; // Sepolia PYUSD
    
    event FamilyDeposited(address indexed family, uint256 amount);
    event PositionRebalanced(uint256 oldPrice, uint256 newPrice);
    
    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}
    
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
    
    // Family deposits PYUSD, we convert to ETH-PYUSD and add to whale pool
    function deposit(uint256 pyusdAmount, bytes[] calldata pythUpdateData) external payable {
        // Update Pyth price feeds
        uint updateFee = PYTH.getUpdateFee(pythUpdateData);
        PYTH.updatePriceFeeds{value: updateFee}(pythUpdateData);
        
        // Get current ETH price
        IPyth.Price memory ethPrice = PYTH.getPriceUnsafe(ETH_USD_PRICE_FEED);
        uint256 ethPriceUsd = uint256(uint64(ethPrice.price)) * (10 ** uint256(uint32(-ethPrice.expo)));
        
        // Transfer PYUSD from user
        IERC20(PYUSD).transferFrom(msg.sender, address(this), pyusdAmount);
        
        // Calculate how much ETH we need to buy with half the PYUSD
        uint256 pyusdForEth = pyusdAmount / 2;
        uint256 ethNeeded = (pyusdForEth * 1e18) / ethPriceUsd; // Convert to ETH amount
        
        // Track family position
        if (familyPositions[msg.sender].pyusdDeposited == 0) {
            families.push(msg.sender);
        }
        
        familyPositions[msg.sender].pyusdDeposited += pyusdAmount;
        totalPyusdDeposited += pyusdAmount;
        
        // Update share percentages
        _updateShares();
        
        emit FamilyDeposited(msg.sender, pyusdAmount);
        
        // TODO: In next step, we'll swap PYUSD for ETH and add liquidity
    }
    
    function _updateShares() internal {
        for (uint i = 0; i < families.length; i++) {
            familyPositions[families[i]].sharePercentage = 
                (familyPositions[families[i]].pyusdDeposited * 10000) / totalPyusdDeposited;
        }
    }
    
    // Check if rebalancing is needed
    function shouldRebalance(bytes[] calldata pythUpdateData) external returns (bool) {
        uint updateFee = PYTH.getUpdateFee(pythUpdateData);
        PYTH.updatePriceFeeds{value: updateFee}(pythUpdateData);
        
        IPyth.Price memory ethPrice = PYTH.getPriceUnsafe(ETH_USD_PRICE_FEED);
        uint256 currentPrice = uint256(uint64(ethPrice.price));
        
        // Check against last rebalance price for any family (simplified)
        if (families.length > 0) {
            uint256 lastPrice = familyPositions[families[0]].lastRebalancePrice;
            if (lastPrice > 0) {
                uint256 priceDiff = currentPrice > lastPrice ? 
                    ((currentPrice - lastPrice) * 10000) / lastPrice :
                    ((lastPrice - currentPrice) * 10000) / lastPrice;
                    
                return priceDiff > REBALANCE_THRESHOLD;
            }
        }
        return false;
    }
    
    // Hook callbacks (simplified for now)
    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        //IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        return BaseHook.beforeAddLiquidity.selector;
    }
    
    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        return (BaseHook.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }
    
    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) internal override returns (bytes4) {
        return BaseHook.beforeRemoveLiquidity.selector;
    }
}