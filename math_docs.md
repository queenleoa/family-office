# Complete LP Diversification Calculation Methodology - AI calculator

## Core Formulas

### 1. Base Impermanent Loss Formula (Constant Product AMM)

For any price change from initial price P₀ to final price P₁:

```
Price Ratio: k = P₁ / P₀

IL = (2 × √k) / (1 + k) - 1
```

**Example**: ETH goes from $4,200 to $8,400
- k = 8400/4200 = 2
- IL = (2 × √2) / (1 + 2) - 1 = 2.828/3 - 1 = -0.0572 = **-5.72%**

### 2. Concentrated Liquidity IL Multiplier

For positions with defined ranges [P_min, P_max]:

```
Range Width = (P_max - P_min) / P_current
Concentration Factor = 2 / Range Width  (approximation for ±50% baseline)

Concentrated IL = Base IL × Concentration Factor
```

**Example**: Position with range [$3,360, $5,040] at current price $4,200
- Range Width = (5040 - 3360) / 4200 = 0.40 (40% range)
- Concentration Factor = 2 / 0.40 = 5x
- If Base IL = -5.72%, Concentrated IL = -5.72% × 5 = **-28.6%**

### 3. In-Range Check

Position experiences IL only when price stays within range:

```python
def is_in_range(new_price, range_min, range_max):
    return range_min <= new_price <= range_max
```

Out-of-range positions:
- **Above range**: Position is 100% in quote token (USDC) - sold high
- **Below range**: Position is 100% in base token (ETH) - waiting to sell

## Step-by-Step Calculation Process

### Step 1: Define Your Positions

**Individual Example** ($10,000):
```javascript
const individual = {
    capital: 10000,
    range: [3360, 5040],  // ±20% range
    fee_tier: 0.003       // 0.3%
}
```

**Collective Example** ($1,000,000):
```javascript
const positions = [
    { name: "Wide", allocation: 0.20, range: [2520, 5880], fee_tier: 0.003 },
    { name: "Medium", allocation: 0.25, range: [3150, 5250], fee_tier: 0.003 },
    { name: "Tight", allocation: 0.20, range: [3570, 4830], fee_tier: 0.001 },
    { name: "V-Tight", allocation: 0.15, range: [3864, 4536], fee_tier: 0.0005 },
    { name: "Buy-Zone", allocation: 0.10, range: [2500, 3200], fee_tier: 0.01 },
    { name: "Sell-Zone", allocation: 0.10, range: [5500, 7000], fee_tier: 0.01 }
]
```

### Step 2: Calculate IL for Each Position

For each position and price scenario:

```javascript
function calculatePositionIL(position, initial_price, new_price) {
    // Check if in range
    if (new_price < position.range[0] || new_price > position.range[1]) {
        return {
            in_range: false,
            il_amount: 0,
            opportunity_cost: calculateOpportunityCost(position, initial_price, new_price)
        }
    }
    
    // Calculate concentrated IL
    const price_ratio = new_price / initial_price
    const base_il = (2 * Math.sqrt(price_ratio)) / (1 + price_ratio) - 1
    
    const range_width = (position.range[1] - position.range[0]) / initial_price
    const concentration = 2 / range_width  // Approximation
    
    const concentrated_il = base_il * concentration
    const il_amount = concentrated_il * position.capital
    
    return {
        in_range: true,
        il_amount: il_amount,
        concentration: concentration
    }
}
```

### Step 3: Calculate Fee Income

Simplified fee calculation based on:
- Capital deployed
- Fee tier
- Time period
- Capital efficiency (for concentrated positions)
- Volatility multiplier

```javascript
function calculateFees(position, days, volatility_factor) {
    if (!position.in_range) return 0
    
    const base_daily_volume = position.capital * 10  // Assume 10x daily volume
    const fee_income = base_daily_volume * position.fee_tier * days
    const efficiency_boost = position.concentration || 1
    const volatility_boost = 1 + (Math.abs(volatility_factor) / 20)
    
    return fee_income * efficiency_boost * volatility_boost
}
```

### Step 4: Handle Out-of-Range Positions

```javascript
function calculateOpportunityCost(position, initial_price, new_price) {
    if (new_price > position.range[1]) {
        // Sold early - missed upside
        const missed_gains = (new_price - position.range[1]) / initial_price
        return -position.capital * missed_gains * 0.5  // 50% penalty
    } else if (new_price < position.range[0]) {
        // Waiting to enter - missed fees
        return -position.capital * 0.05  // 5% opportunity cost
    }
    return 0
}
```

### Step 5: Aggregate Results

**For Collective Pool**:
```javascript
function calculateCollectiveResults(positions, initial_price, new_price) {
    let total_il = 0
    let total_fees = 0
    let active_count = 0
    
    for (const pos of positions) {
        const capital = pos.allocation * 1000000
        const result = calculatePositionIL(
            {...pos, capital}, 
            initial_price, 
            new_price
        )
        
        if (result.in_range) {
            total_il += result.il_amount
            total_fees += calculateFees({...result, capital}, 30, price_change)
            active_count++
        } else {
            total_il += result.opportunity_cost
        }
    }
    
    return {
        total_il,
        total_fees,
        net_position: total_il + total_fees,
        per_family: (total_il + total_fees) / 100,
        active_positions: active_count
    }
}
```

## Complete Working Example

### Scenario: ETH $4,200 → $8,400 (100% increase)

#### Individual Calculation
```
Position: $3,360 - $5,040 range
Capital: $10,000

1. In-range check: 8400 > 5040 ✗ (Out of range)
2. IL: 0 (not in range)
3. Opportunity cost: -$10,000 × 50% = -$5,000
4. Fees: $0 (out of range)
5. Net: -$5,000
```

#### Collective Calculation
```
Position 1 (Wide ±40%): $2,520-$5,880
- Capital: $200,000
- In range? 8400 > 5880 ✗
- Status: Sold high at $5,880
- IL: $0
- Fees earned before exit: $200,000 × 0.003 × 15 days = $9,000
- Opportunity gain: +$10,000 (sold before crash)

Position 2 (Medium ±25%): $3,150-$5,250
- Capital: $250,000  
- In range? 8400 > 5250 ✗
- Status: Sold high at $5,250
- IL: $0
- Fees earned: $250,000 × 0.003 × 12 days = $9,000

[Continue for all 6 positions...]

Total IL: -$10
Total Fees: $40,855
Net: $40,845
Per Family: $408.45 (4.08% return)
```

## Verification Checklist

To verify calculations:

1. **IL Calculation**
   - Use formula: `IL = 2√k/(1+k) - 1`
   - Multiply by concentration factor for narrow ranges
   - Only applies when in range

2. **Fee Calculation**
   - Base: Capital × Fee Tier × Days
   - Adjust for concentration (narrow = more fees)
   - Adjust for volatility (more movement = more volume)

3. **Out-of-Range Handling**
   - Above range: Track at what price it exited
   - Below range: Calculate opportunity cost
   - Consider single-sided exposure

4. **Risk Metrics**
   ```javascript
   // Standard Deviation
   const returns = scenarios.map(s => s.net / initial_capital)
   const mean = returns.reduce((a,b) => a+b) / returns.length
   const variance = returns.reduce((sum, r) => 
       sum + Math.pow(r - mean, 2), 0) / returns.length
   const std_dev = Math.sqrt(variance)
   ```

## Python Implementation Template

```python
import numpy as np

def calculate_il(price_ratio):
    """Base IL formula for constant product AMM"""
    k = price_ratio
    return 2 * np.sqrt(k) / (1 + k) - 1

def concentrated_il(base_il, range_min, range_max, current_price):
    """Apply concentration multiplier to base IL"""
    range_width = (range_max - range_min) / current_price
    concentration = 2 / range_width  # Approximation
    return base_il * concentration

def calculate_position_outcome(position, initial_price, new_price, days=30):
    """Complete position P&L calculation"""
    capital = position['allocation'] * 1_000_000
    
    # Check if in range
    if not (position['range'][0] <= new_price <= position['range'][1]):
        # Out of range - calculate opportunity cost
        if new_price > position['range'][1]:
            # Sold high
            exit_price = position['range'][1]
            captured_gain = (exit_price - initial_price) / initial_price
            return {
                'il': 0,
                'fees': capital * position['fee_tier'] * 10,  # Partial fees
                'opportunity': capital * captured_gain * 0.2  # Bonus for selling high
            }
        else:
            # Never entered
            return {
                'il': 0,
                'fees': 0,
                'opportunity': -capital * 0.05  # Opportunity cost
            }
    
    # In range - calculate IL and fees
    price_ratio = new_price / initial_price
    base_il = calculate_il(price_ratio)
    
    range_width = (position['range'][1] - position['range'][0]) / initial_price
    concentration = 2 / range_width
    
    il_amount = base_il * concentration * capital
    fee_income = capital * position['fee_tier'] * days * concentration
    
    return {
        'il': il_amount,
        'fees': fee_income,
        'opportunity': 0
    }

# Example usage
positions = [
    {'name': 'Wide', 'allocation': 0.20, 'range': [2520, 5880], 'fee_tier': 0.003},
    {'name': 'Medium', 'allocation': 0.25, 'range': [3150, 5250], 'fee_tier': 0.003},
    # ... add more positions
]

initial_price = 4200
scenarios = [2100, 3360, 4200, 5460, 6300, 8400]

for new_price in scenarios:
    total_il = 0
    total_fees = 0
    total_opportunity = 0
    
    for pos in positions:
        result = calculate_position_outcome(pos, initial_price, new_price)
        total_il += result['il']
        total_fees += result['fees']
        total_opportunity += result['opportunity']
    
    net = total_il + total_fees + total_opportunity
    per_family = net / 100
    
    print(f"ETH = ${new_price}: Net = ${net:,.0f}, Per Family = ${per_family:.2f}")
```

## Key Assumptions to Document

When running your own calculations, document these assumptions:

1. **Volume Assumptions**: Daily volume = 10x position size (adjust based on pool)
2. **Concentration Approximation**: 2/range_width (more accurate models exist)
3. **Opportunity Cost**: 50% penalty for missing moves (adjust based on strategy)
4. **Fee Collection Period**: How many days in range before price moves
5. **Slippage/MEV**: Not included in basic model (subtract 0.1-0.3% if needed)

## Validation Tips

1. **Sanity Check IL**: Should be between 0% and -50% for 2x price moves
2. **Fee Reasonableness**: Annual fees rarely exceed 50% APY even in tight ranges
3. **Total Returns**: Should align with historical pool performance data
4. **Risk Metrics**: Diversified Sharpe ratio should be 2-3x individual