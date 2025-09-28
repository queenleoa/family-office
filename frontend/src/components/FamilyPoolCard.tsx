// frontend/src/components/FamilyPoolCard.tsx
import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Users, Plus, CheckCircle } from 'lucide-react';

interface FamilyMember {
  name: string;
  address: string;
  amount: number;
  avatar: string;
}

const mockFamilyMembers: FamilyMember[] = [
  { name: 'Mom', address: '0x1234...5678', amount: 1000, avatar: '👩' },
  { name: 'Dad', address: '0x2345...6789', amount: 1500, avatar: '👨' },
  { name: 'Sister', address: '0x3456...7890', amount: 500, avatar: '👧' },
];

const FamilyPoolCard: React.FC<{ onDeposit: () => void; hasDeposited: boolean }> = ({ 
  onDeposit, 
  hasDeposited 
}) => {
  const [depositAmount, setDepositAmount] = useState('1000');
  const [isDepositing, setIsDepositing] = useState(false);

  const handleDeposit = async () => {
    setIsDepositing(true);
    // Simulate transaction
    await new Promise(resolve => setTimeout(resolve, 2000));
    setIsDepositing(false);
    onDeposit();
  };

  const totalPooled = mockFamilyMembers.reduce((sum, member) => sum + member.amount, 0);

  return (
    <motion.div className="pool-card">
      <div className="card-header">
        <h2>Family Pool</h2>
        <div className="pool-stats">
          <span className="member-count">
            <Users size={16} />
            {hasDeposited ? '4 Members' : '3 Members'}
          </span>
          <span className="apy">10.5% APY</span>
        </div>
      </div>

      <div className="family-members">
        {mockFamilyMembers.map((member, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.1 }}
            className="member-row"
          >
            <span className="member-avatar">{member.avatar}</span>
            <div className="member-info">
              <span className="member-name">{member.name}</span>
              <span className="member-address">{member.address}</span>
            </div>
            <span className="member-amount">{member.amount} PYUSD</span>
          </motion.div>
        ))}
        
        {hasDeposited && (
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            className="member-row you"
          >
            <span className="member-avatar">🫵</span>
            <div className="member-info">
              <span className="member-name">You</span>
              <span className="member-address">0x4567...8901</span>
            </div>
            <span className="member-amount">{depositAmount} PYUSD</span>
          </motion.div>
        )}
      </div>

      <div className="total-pooled">
        <span>Total Pooled</span>
        <span className="total-amount">
          {hasDeposited ? totalPooled + parseInt(depositAmount) : totalPooled} PYUSD
        </span>
      </div>

      {!hasDeposited ? (
        <div className="deposit-section">
          <input
            type="number"
            value={depositAmount}
            onChange={(e) => setDepositAmount(e.target.value)}
            placeholder="Amount in PYUSD"
            className="deposit-input"
          />
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleDeposit}
            disabled={isDepositing}
            className="deposit-btn"
          >
            {isDepositing ? (
              <span className="loading">Depositing...</span>
            ) : (
              <>
                <Plus size={20} />
                One-Click Pool
              </>
            )}
          </motion.button>
        </div>
      ) : (
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          className="success-message"
        >
          <CheckCircle className="success-icon" />
          <span>Successfully Joined Family Pool!</span>
        </motion.div>
      )}
    </motion.div>
  );
};

export default FamilyPoolCard;