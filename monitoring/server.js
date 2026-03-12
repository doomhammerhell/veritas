const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const winston = require('winston');
const promClient = require('prom-client');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
const API_URL = process.env.MONITORING_API_URL || 'http://localhost:3000';

// Configure Prometheus metrics
const collectDefaultMetrics = promClient.collectDefaultMetrics;
const register = new promClient.Registry();
collectDefaultMetrics({ register });

const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

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
    new winston.transports.File({ filename: 'monitoring.log' })
  ]
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    httpRequestDurationMicroseconds
      .labels(req.method, req.route?.path || req.path, res.statusCode.toString())
      .observe(duration);
    httpRequestTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode.toString())
      .inc();
  });
  next();
});

// Health check endpoint
app.get('/monitoring/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'veritas-monitoring',
    version: '1.0.0',
    uptime: process.uptime()
  });
});

// Metrics endpoint
app.get('/monitoring/metrics', async (req, res) => {
  try {
    const metrics = await register.metrics();
    res.set('Content-Type', register.contentType);
    res.end(metrics);
  } catch (error) {
    logger.error('Error fetching metrics:', error);
    res.status(500).json({ error: 'Failed to fetch metrics' });
  }
});

// Dashboard endpoint
app.get('/monitoring/dashboard', async (req, res) => {
  try {
    const response = await axios.get(`${API_URL}/api/status`);
    const apiStatus = response.data;
    
    res.json({
      service: 'veritas-monitoring',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      api: apiStatus,
      metrics: {
        totalRequests: httpRequestTotal.get(),
        averageResponseTime: httpRequestDurationMicroseconds.get()
      }
    });
  } catch (error) {
    logger.error('Error fetching API status:', error);
    res.status(500).json({ error: 'Failed to fetch API status' });
  }
});

// Alerting endpoint
app.get('/monitoring/alerts', (req, res) => {
  const alerts = [
    {
      type: 'info',
      message: 'Monitoring service is running',
      timestamp: new Date().toISOString(),
      severity: 'low'
    }
  ];
  
  res.json({
    service: 'veritas-monitoring',
    alerts,
    total: alerts.length
  });
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
  logger.info(`Veritas Monitoring Service running on port ${PORT}`);
  logger.info(`Metrics available at http://localhost:${PORT}/monitoring/metrics`);
  logger.info(`Dashboard available at http://localhost:${PORT}/monitoring/dashboard`);
});

module.exports = app;
