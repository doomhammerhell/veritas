const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const winston = require('winston');
const axios = require('axios');
const moment = require('moment');
const _ = require('lodash');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3002;
const API_URL = process.env.ANALYTICS_API_URL || 'http://localhost:3000';

// Configure Winston logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    }),
    new winston.transports.File({ filename: 'analytics.log' })
  ]
});

// In-memory analytics storage
const analyticsData = {
  votes: [],
  users: [],
  transactions: [],
  performance: {},
  dailyStats: {}
};

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Health check endpoint
app.get('/analytics/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'veritas-analytics',
    version: '1.0.0',
    uptime: process.uptime()
  });
});

// Record vote event
app.post('/analytics/vote', (req, res) => {
  try {
    const voteData = {
      ...req.body,
      timestamp: new Date().toISOString(),
      id: Date.now().toString()
    };
    
    analyticsData.votes.push(voteData);
    logger.info('Vote recorded:', voteData);
    
    res.status(201).json({ success: true, id: voteData.id });
  } catch (error) {
    logger.error('Error recording vote:', error);
    res.status(500).json({ error: 'Failed to record vote' });
  }
});

// Record user activity
app.post('/analytics/user', (req, res) => {
  try {
    const userData = {
      ...req.body,
      timestamp: new Date().toISOString(),
      id: Date.now().toString()
    };
    
    analyticsData.users.push(userData);
    logger.info('User activity recorded:', userData);
    
    res.status(201).json({ success: true, id: userData.id });
  } catch (error) {
    logger.error('Error recording user activity:', error);
    res.status(500).json({ error: 'Failed to record user activity' });
  }
});

// Record transaction
app.post('/analytics/transaction', (req, res) => {
  try {
    const transactionData = {
      ...req.body,
      timestamp: new Date().toISOString(),
      id: Date.now().toString()
    };
    
    analyticsData.transactions.push(transactionData);
    logger.info('Transaction recorded:', transactionData);
    
    res.status(201).json({ success: true, id: transactionData.id });
  } catch (error) {
    logger.error('Error recording transaction:', error);
    res.status(500).json({ error: 'Failed to record transaction' });
  }
});

// Get voting analytics
app.get('/analytics/votes', (req, res) => {
  try {
    const { startDate, endDate, limit = 100 } = req.query;
    
    let filteredVotes = analyticsData.votes;
    
    if (startDate) {
      filteredVotes = filteredVotes.filter(v => 
        moment(v.timestamp).isAfter(moment(startDate))
      );
    }
    
    if (endDate) {
      filteredVotes = filteredVotes.filter(v => 
        moment(v.timestamp).isBefore(moment(endDate))
      );
    }
    
    const analytics = {
      totalVotes: filteredVotes.length,
      votesByChoice: _.groupBy(filteredVotes, 'choice'),
      votesByTime: _.groupBy(filteredVotes, v => 
        moment(v.timestamp).format('YYYY-MM-DD')
      ),
      recentVotes: filteredVotes.slice(-limit)
    };
    
    res.json(analytics);
  } catch (error) {
    logger.error('Error fetching vote analytics:', error);
    res.status(500).json({ error: 'Failed to fetch analytics' });
  }
});

// Get user analytics
app.get('/analytics/users', (req, res) => {
  try {
    const { startDate, endDate, limit = 100 } = req.query;
    
    let filteredUsers = analyticsData.users;
    
    if (startDate) {
      filteredUsers = filteredUsers.filter(u => 
        moment(u.timestamp).isAfter(moment(startDate))
      );
    }
    
    if (endDate) {
      filteredUsers = filteredUsers.filter(u => 
        moment(u.timestamp).isBefore(moment(endDate))
      );
    }
    
    const analytics = {
      totalUsers: filteredUsers.length,
      activeUsers: filteredUsers.filter(u => u.type === 'active').length,
      usersByAction: _.groupBy(filteredUsers, 'action'),
      recentUsers: filteredUsers.slice(-limit)
    };
    
    res.json(analytics);
  } catch (error) {
    logger.error('Error fetching user analytics:', error);
    res.status(500).json({ error: 'Failed to fetch user analytics' });
  }
});

// Get transaction analytics
app.get('/analytics/transactions', (req, res) => {
  try {
    const { startDate, endDate, limit = 100 } = req.query;
    
    let filteredTransactions = analyticsData.transactions;
    
    if (startDate) {
      filteredTransactions = filteredTransactions.filter(t => 
        moment(t.timestamp).isAfter(moment(startDate))
      );
    }
    
    if (endDate) {
      filteredTransactions = filteredTransactions.filter(t => 
        moment(t.timestamp).isBefore(moment(endDate))
      );
    }
    
    const analytics = {
      totalTransactions: filteredTransactions.length,
      transactionsByType: _.groupBy(filteredTransactions, 'type'),
      transactionsByStatus: _.groupBy(filteredTransactions, 'status'),
      averageGasCost: _.meanBy(filteredTransactions, 'gasCost'),
      recentTransactions: filteredTransactions.slice(-limit)
    };
    
    res.json(analytics);
  } catch (error) {
    logger.error('Error fetching transaction analytics:', error);
    res.status(500).json({ error: 'Failed to fetch transaction analytics' });
  }
});

// Get dashboard data
app.get('/analytics/dashboard', async (req, res) => {
  try {
    const response = await axios.get(`${API_URL}/api/status`);
    const apiStatus = response.data;
    
    const dashboard = {
      service: 'veritas-analytics',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      api: apiStatus,
      analytics: {
        totalVotes: analyticsData.votes.length,
        totalUsers: analyticsData.users.length,
        totalTransactions: analyticsData.transactions.length,
        recentActivity: {
          votes: analyticsData.votes.slice(-10),
          users: analyticsData.users.slice(-10),
          transactions: analyticsData.transactions.slice(-10)
        }
      }
    };
    
    res.json(dashboard);
  } catch (error) {
    logger.error('Error fetching dashboard data:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

// Get performance metrics
app.get('/analytics/performance', (req, res) => {
  try {
    const performance = {
      service: 'veritas-analytics',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      requests: {
        total: analyticsData.votes.length + analyticsData.users.length + analyticsData.transactions.length,
        votes: analyticsData.votes.length,
        users: analyticsData.users.length,
        transactions: analyticsData.transactions.length
      },
      errors: analyticsData.errors || []
    };
    
    res.json(performance);
  } catch (error) {
    logger.error('Error fetching performance metrics:', error);
    res.status(500).json({ error: 'Failed to fetch performance metrics' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(`Veritas Analytics Service running on port ${PORT}`);
  logger.info(`Analytics API available at http://localhost:${PORT}/analytics`);
});

module.exports = app;
