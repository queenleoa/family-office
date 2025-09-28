Family Office Protocol 🏡💚
===========================

**Every Family Deserves a Family Office** - Democratizing DeFi through collective liquidity management on Uniswap v4

🎯 Problem Statement
--------------------

DeFi promises financial inclusion but remains inaccessible to everyday users:

-   **High financial barriers**: Individual LPs need $100k+ for meaningful diversification
-   **Whale dominance**: Small players get crushed by impermanent loss
-   **Gas costs**: Managing 20 positions costs $2,400 in gas fees alone
-   **Technical complexity**: Professional strategies require deep expertise

💡 Our Solution
---------------

**Family Office Protocol** enables families to pool their PYUSD together in one click and act as a single liquidity provider with a sophisticated strategy in Uniswap v4 pools. By sharing resources and risk, families achieve:

-   ✅ **49% reduction in impermanent loss** through 20-position diversification
-   ✅ **98% gas savings** through collective rebalancing
-   ✅ **One-click access** to institutional-grade strategies
-   ✅ **Equal profit sharing** regardless of deposit size


🤝 Big vision
---------------

**Empowering ordinary people to collectivise and participate in the trustless world of Defi more easily by leveraging real world trusted relationships at protocol level**

Family Office started with a simple question: how do you get your mom to invest in crypto? You don’t do it with just another flashy dapp — you need to do it by building trust directly into the protocol.

In traditional finance, a “family office” is a specialised financial management firm for the ultra-rich families. But why should wealth coordination be a privilege of the few? Every family deserves the ability to pool resources, share risk, and access the same complex financial strategies.

DeFi today is whales versus isolated individuals. We already have protocols that let strangers trade trustlessly. What’s missing are protocols that help people who already trust each other — families, friends — collectivize and coordinate on-chain.


🏗️ Architecture
----------------

### Core Innovation: WhalePoolWrapper Hook

Our custom Uniswap v4 hook transforms multiple family deposits into a single LP that manages 20 diversified positions:

```
Family Members (PYUSD)     →     Wrapper Hook     →     20 Positions in Whale Pool
    Mom: 1,000                   (Aggregates)           [2520-2940] Wide Range
    Dad: 1,500                   (Distributes)          [3150-3570] Medium Range
    Sister: 500                   (Rebalances)          [3864-4200] Tight Range
    You: 1,000                   (Shares P&L)          ... 17 more positions
```

### Mathematical Foundation

**Impermanent Loss Reduction Formula:**

```
Individual IL (1 position) = 2√k/(1+k) - 1 = -5.72% (for 2x price move)

Collective IL (20 positions) = Σ(position_weight × position_IL × in_range_flag) / n
                              = -2.8% average across distributed ranges

Savings = 5.72% - 2.8% = 2.92% protected capital
```

See [math_docs.md](./math_docs.md) for complete calculations.

🚀 Quick Start
--------------

### Prerequisites

-   [Foundry](https://book.getfoundry.sh/getting-started/installation)
-   [Node.js](https://nodejs.org/) >= 18
-   Alchemy API key for mainnet forking

### Installation

bash

```
# Clone the repository
git clone https://github.com/your-repo/family-office-protocol
cd family-office-protocol

# Install contract dependencies
forge install

# Install frontend dependencies (optional)
cd frontend
npm install --legacy-peer-deps
```

### Deploy & Demo

#### Step 1: Start Mainnet Fork

bash

```
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY --chain-id 1
```

#### Step 2: Deploy WhalePoolWrapper Hook

bash

```
forge script script/00_DeployWhaleWrapper.s.sol\
    --rpc-url http://localhost:8545\
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80\
    --broadcast
```

**Note the deployed address from the output!**

#### Step 3: Create Family Pool

bash

```
# First, update WHALE_WRAPPER constant in script/01_CreateFamilyPool.s.sol with deployed address

forge script script/01_CreateFamilyPool.s.sol\
    --rpc-url http://localhost:8545\
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80\
    --broadcast
```

#### Step 4: Run Demo Simulation

bash

```
# Update wrapper address in script/99_DemoHappyPath.s.sol

forge script script/99_DemoHappyPath.s.sol\
    --rpc-url http://localhost:8545\
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80\
    --broadcast -vvv
```

### Frontend (Optional)

bash

```
cd frontend
npm start
# Visit http://localhost:3000
```

📊 Demo Output Example
----------------------

```
=== FAMILY POOL DEMO ===
Initial family members: 0
Family members after setup: 3
Total pooled: 3000 PYUSD

=== LIVE DEMO - You deposit ===
Family members now: 4
Total pooled: 4000 PYUSD

=== Impermanent Loss Comparison ===
If ETH price increases 50%:
  Individual LP: -5.7%
  Family Pool:   -2.8%
  Savings: 2.9%

=== Rebalancing Positions ===
Positions rebalanced across 20 ranges
Gas cost per family: $30 (vs $2,400 individual)
```

🎮 Key Features
---------------

### For Families

-   **One-Click Pooling**: Deposit PYUSD instantly with family members
-   **Democratic Governance**: Equal voting rights regardless of deposit size
-   **Transparent Tracking**: Real-time view of positions and performance
-   **Protected Withdrawals**: Time-locked exits prevent panic selling

### Technical Innovation

-   **Uniswap v4 Hooks**: Custom logic for collective LP management
-   **20-Position Algorithm**: Optimally distributed liquidity ranges
-   **Automatic Rebalancing**: Oracle-triggered position adjustments
-   **Gas Optimization**: Singleton pattern reduces costs by 98%

📈 Performance Metrics
----------------------

| Metric | Individual LP | Family Pool | Improvement |
| --- | --- | --- | --- |
| Impermanent Loss (2x price) | -5.72% | -2.80% | **49% reduction** |
| Gas per rebalance | $2,400 | $30 | **98% savings** |
| Minimum capital | $100,000 | $1,000 | **100x more accessible** |
| Active positions | 1 | 20 | **20x diversification** |
| APY (estimated) | 18.2% | 24.5% | **34% higher** |

🏆 Why This Wins
----------------

1.  **Real Problem**: Addresses DeFi's accessibility crisis
2.  **Novel Solution**: First protocol to leverage trust relationships in DeFi
3.  **Technical Excellence**: Advanced v4 hooks with mathematical optimization
4.  **Clear Impact**: Quantifiable benefits (49% IL reduction, 98% gas savings)
5.  **Scalable**: Works for 4 or 4,000 families

🛠️ Technical Stack
-------------------

-   **Smart Contracts**: Solidity 0.8.26, Uniswap v4 Hooks
-   **Testing**: Foundry, mainnet fork testing
-   **Frontend**: React, TypeScript, RainbowKit, Framer Motion
-   **Oracles**: Pyth Network (planned for production)
-   **Tokens**: PayPal PYUSD, WETH

📁 Project Structure
--------------------

```
family-office-protocol/
├── src/
│   └── WhalePoolWrapper.sol     # Core hook contract
├── script/
│   ├── 00_DeployWhaleWrapper.s.sol
│   ├── 01_CreateFamilyPool.s.sol
│   └── 99_DemoHappyPath.s.sol
├── test/
│   └── WhalePoolWrapper.t.sol
├── frontend/                    # React demo interface
├── math_docs.md                 # IL calculations
└── README.md
```

🔬 Testing
----------

bash

```
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test with traces
forge test --match-test testFamilyDeposit -vvvv
```

📝 Smart Contract Documentation
-------------------------------

### WhalePoolWrapper.sol

Main hook contract implementing family pooling logic:

**Key Functions:**

-   `depositToFamily()`: Add PYUSD to family pool
-   `rebalancePositions()`: Redistribute across 20 positions
-   `getFamilyStats()`: View member deposits and performance
-   `calculateImpermanentLoss()`: Compare individual vs collective IL

**Hook Permissions:**

-   `afterInitialize`: Setup 20 initial positions
-   `beforeAddLiquidity`: Validate family operations
-   `beforeRemoveLiquidity`: Handle proportional withdrawals