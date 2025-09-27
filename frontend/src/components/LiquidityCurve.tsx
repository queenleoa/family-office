// frontend/src/components/LiquidityCurve.tsx
import React from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, Area, AreaChart } from 'recharts';
import { motion } from 'framer-motion';

const LiquidityCurve: React.FC<{ hasDeposited: boolean }> = ({ hasDeposited }) => {
  // Generate curve data
  const individualData = Array.from({ length: 100 }, (_, i) => {
    const x = i - 50;
    const liquidity = Math.exp(-Math.pow(x, 2) / 200) * 100;
    return { price: x, liquidity, il: x > 0 ? -5.7 : 0 };
  });

  const familyData = Array.from({ length: 100 }, (_, i) => {
    const x = i - 50;
    // Multiple overlapping curves for 20 positions
    let totalLiquidity = 0;
    for (let j = 0; j < 20; j++) {
      const offset = (j - 10) * 5;
      totalLiquidity += Math.exp(-Math.pow(x - offset, 2) / 400) * 15;
    }
    return { 
      price: x, 
      liquidity: totalLiquidity,
      il: x > 0 ? -2.8 : 0 
    };
  });

  return (
    <motion.div className="curve-card">
      <h3>Liquidity Distribution</h3>
      <div className="curve-comparison">
        <div className="curve-section">
          <h4 className={!hasDeposited ? 'active' : ''}>
            Individual Position
          </h4>
          <AreaChart width={300} height={200} data={individualData}>
            <defs>
              <linearGradient id="redGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#ff6b6b" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#ff6b6b" stopOpacity={0.1}/>
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="price" />
            <YAxis />
            <Tooltip />
            <Area type="monotone" dataKey="liquidity" stroke="#ff6b6b" fill="url(#redGradient)" />
          </AreaChart>
          <div className="il-display">
            <span>Impermanent Loss: </span>
            <span className="il-value negative">-5.7%</span>
          </div>
        </div>

        <div className="curve-section">
          <h4 className={hasDeposited ? 'active' : ''}>
            Family Pool (20 Positions)
          </h4>
          <AreaChart width={300} height={200} data={familyData}>
            <defs>
              <linearGradient id="greenGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#22c55e" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#22c55e" stopOpacity={0.1}/>
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="price" />
            <YAxis />
            <Tooltip />
            <Area type="monotone" dataKey="liquidity" stroke="#22c55e" fill="url(#greenGradient)" />
          </AreaChart>
          <div className="il-display">
            <span>Impermanent Loss: </span>
            <span className="il-value positive">-2.8%</span>
          </div>
        </div>
      </div>
      <div className="savings-highlight">
        <motion.div
          animate={{ scale: hasDeposited ? [1, 1.1, 1] : 1 }}
          className="savings-box"
        >
          💰 You save 2.9% on Impermanent Loss!
        </motion.div>
      </div>
    </motion.div>
  );
};

export default LiquidityCurve;