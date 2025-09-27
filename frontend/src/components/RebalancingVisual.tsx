// frontend/src/components/RebalancingVisual.tsx
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, TrendingUp, RefreshCw } from 'lucide-react';

interface Position {
  id: number;
  range: string;
  liquidity: number;
  isActive: boolean;
}

const RebalancingVisual: React.FC<{ onClose: () => void }> = ({ onClose }) => {
  const [isRebalancing, setIsRebalancing] = useState(false);
  const [positions, setPositions] = useState<Position[]>([]);
  const [ethPrice, setEthPrice] = useState(3000);

  useEffect(() => {
    // Initialize positions
    const initialPositions = Array.from({ length: 20 }, (_, i) => ({
      id: i,
      range: `$${2700 + i * 30} - $${2730 + i * 30}`,
      liquidity: Math.random() * 100,
      isActive: i >= 8 && i <= 12
    }));
    setPositions(initialPositions);
  }, []);

  const handleRebalance = () => {
    setIsRebalancing(true);
    
    // Animate price increase
    const priceInterval = setInterval(() => {
      setEthPrice(prev => {
        if (prev >= 4500) {
          clearInterval(priceInterval);
          return 4500;
        }
        return prev + 50;
      });
    }, 50);

    // Rebalance positions after animation
    setTimeout(() => {
      const newPositions = Array.from({ length: 20 }, (_, i) => ({
        id: i,
        range: `$${4200 + i * 30} - $${4230 + i * 30}`,
        liquidity: Math.random() * 100,
        isActive: i >= 5 && i <= 15
      }));
      setPositions(newPositions);
      setIsRebalancing(false);
    }, 3000);
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="modal-overlay"
      onClick={onClose}
    >
      <motion.div
        initial={{ scale: 0.9, y: 20 }}
        animate={{ scale: 1, y: 0 }}
        exit={{ scale: 0.9, y: 20 }}
        className="rebalancing-modal"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="modal-header">
          <h2>Automatic Rebalancing</h2>
          <button onClick={onClose} className="close-btn">
            <X size={24} />
          </button>
        </div>

        <div className="price-display">
          <div className="price-label">ETH Price</div>
          <motion.div
            key={ethPrice}
            initial={{ scale: 0.8 }}
            animate={{ scale: 1 }}
            className="price-value"
          >
            ${ethPrice.toLocaleString()}
          </motion.div>
          {ethPrice > 3000 && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="price-change"
            >
              <TrendingUp size={16} />
              +{((ethPrice - 3000) / 3000 * 100).toFixed(1)}%
            </motion.div>
          )}
        </div>

        <div className="positions-grid">
          <h3>Liquidity Positions</h3>
          <div className="positions-container">
            {positions.map((position, index) => (
              <motion.div
                key={position.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ 
                  opacity: 1, 
                  y: 0,
                  scale: position.isActive ? 1.05 : 1,
                  backgroundColor: position.isActive ? '#22c55e20' : '#f3f4f6'
                }}
                transition={{ delay: index * 0.02 }}
                className={`position-bar ${position.isActive ? 'active' : ''}`}
              >
                <div className="position-range">{position.range}</div>
                <div className="position-liquidity">
                  <motion.div
                    className="liquidity-fill"
                    animate={{ 
                      width: `${position.liquidity}%`,
                      backgroundColor: position.isActive ? '#22c55e' : '#d1d5db'
                    }}
                    transition={{ duration: 0.5 }}
                  />
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        <div className="rebalance-stats">
          <div className="stat-row">
            <span>Gas Cost (Individual):</span>
            <span className="stat-value negative">$120 × 20 = $2,400</span>
          </div>
          <div className="stat-row">
            <span>Gas Cost (Family Pool):</span>
            <span className="stat-value positive">$120 ÷ 4 = $30</span>
          </div>
          <div className="stat-row highlight">
            <span>Your Savings:</span>
            <span className="stat-value positive">$2,370 (98.75%)</span>
          </div>
        </div>

        {!isRebalancing ? (
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleRebalance}
            className="rebalance-btn"
          >
            <RefreshCw size={20} />
            Simulate Rebalancing
          </motion.button>
        ) : (
          <div className="rebalancing-indicator">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
            >
              <RefreshCw size={24} />
            </motion.div>
            <span>Rebalancing Positions...</span>
          </div>
        )}
      </motion.div>
    </motion.div>
  );
};

export default RebalancingVisual;