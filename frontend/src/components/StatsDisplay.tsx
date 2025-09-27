// frontend/src/components/StatsDisplay.tsx
import React from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, Users, Shield, DollarSign, Award, BarChart3 } from 'lucide-react';

interface StatCardProps {
  icon: React.ReactNode;
  title: string;
  value: string;
  change?: string;
  positive?: boolean;
}

const StatCard: React.FC<StatCardProps> = ({ icon, title, value, change, positive }) => (
  <motion.div
    whileHover={{ y: -2, boxShadow: '0 8px 30px rgba(34, 197, 94, 0.12)' }}
    className="stat-card"
  >
    <div className="stat-icon">{icon}</div>
    <div className="stat-content">
      <div className="stat-title">{title}</div>
      <div className="stat-value">{value}</div>
      {change && (
        <div className={`stat-change ${positive ? 'positive' : 'negative'}`}>
          {change}
        </div>
      )}
    </div>
  </motion.div>
);

const StatsDisplay: React.FC<{ hasDeposited: boolean }> = ({ hasDeposited }) => {
  return (
    <div className="stats-container">
      <h3>Protocol Statistics</h3>
      <div className="stats-grid">
        <StatCard
          icon={<DollarSign />}
          title="Total Value Locked"
          value={hasDeposited ? "$127.4M" : "$126.4M"}
          change="+12.4%"
          positive={true}
        />
        <StatCard
          icon={<Users />}
          title="Active Families"
          value={hasDeposited ? "2,457" : "2,456"}
          change="+156 this week"
          positive={true}
        />
        <StatCard
          icon={<TrendingUp />}
          title="Average APY"
          value="24.5%"
          change="+2.3%"
          positive={true}
        />
        <StatCard
          icon={<Shield />}
          title="IL Protection"
          value="49.1%"
          change="Saved on average"
          positive={true}
        />
        <StatCard
          icon={<Award />}
          title="Total Rewards"
          value="$3.2M"
          change="Distributed this month"
          positive={true}
        />
        <StatCard
          icon={<BarChart3 />}
          title="Trading Volume"
          value="$892M"
          change="+34% vs last month"
          positive={true}
        />
      </div>

      {hasDeposited && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="personal-stats"
        >
          <h4>Your Position</h4>
          <div className="personal-stats-grid">
            <div className="personal-stat">
              <span className="label">Your Share:</span>
              <span className="value">25%</span>
            </div>
            <div className="personal-stat">
              <span className="label">Estimated Earnings:</span>
              <span className="value positive">+$61.25/month</span>
            </div>
            <div className="personal-stat">
              <span className="label">IL Saved:</span>
              <span className="value positive">$29.00</span>
            </div>
          </div>
        </motion.div>
      )}
    </div>
  );
};

export default StatsDisplay;