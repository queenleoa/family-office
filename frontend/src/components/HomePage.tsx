// frontend/src/components/HomePage.tsx
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Users, TrendingUp, Shield, DollarSign } from 'lucide-react';
import FamilyPoolCard from './FamilyPoolCard';
import LiquidityCurve from './LiquidityCurve';
import RebalancingVisual from './RebalancingVisual';
import StatsDisplay from './StatsDisplay';
import './HomePage.css';

const HomePage: React.FC = () => {
  const [hasDeposited, setHasDeposited] = useState(false);
  const [showRebalancing, setShowRebalancing] = useState(false);

  return (
    <div className="app-container">
      {/* Header */}
      <header className="header">
        <div className="header-content">
          <div className="logo-section">
            <div className="logo">
              <Users className="logo-icon" />
              <span className="logo-text">Family Office</span>
            </div>
            <span className="tagline">Every Family Deserves a Hedge Fund</span>
          </div>
          <ConnectButton />
        </div>
      </header>

      {/* Hero Section */}
      <section className="hero">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="hero-content"
        >
          <h1 className="hero-title">
            Pool PYUSD with Your Family
            <br />
            <span className="gradient-text">Share Risk, Multiply Returns</span>
          </h1>
          <p className="hero-subtitle">
            Instead of competing alone in whale-dominated pools, families can now pool
            their PYUSD with one click and access sophisticated liquidity strategies.
          </p>
        </motion.div>

        {/* Powered By */}
        <div className="powered-by">
          <span>Powered by</span>
          <img src="/paypal-logo.png" alt="PayPal" className="partner-logo" />
          <span>&</span>
          <img src="/uniswap-logo.png" alt="Uniswap" className="partner-logo" />
        </div>
      </section>

      {/* Main Content */}
      <div className="main-content">
        <div className="content-grid">
          {/* Left Column - Pool Card */}
          <div className="left-column">
            <FamilyPoolCard 
              onDeposit={() => setHasDeposited(true)}
              hasDeposited={hasDeposited}
            />
            <StatsDisplay hasDeposited={hasDeposited} />
          </div>

          {/* Right Column - Visualizations */}
          <div className="right-column">
            <LiquidityCurve hasDeposited={hasDeposited} />
            {hasDeposited && (
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                className="rebalance-section"
              >
                <button 
                  onClick={() => setShowRebalancing(true)}
                  className="simulate-btn"
                >
                  Simulate Price Movement (ETH +50%)
                </button>
              </motion.div>
            )}
          </div>
        </div>
      </div>

      {/* Rebalancing Modal */}
      <AnimatePresence>
        {showRebalancing && (
          <RebalancingVisual onClose={() => setShowRebalancing(false)} />
        )}
      </AnimatePresence>
    </div>
  );
};

export default HomePage;