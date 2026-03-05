# Veritas Monitoring System

## Overview

Comprehensive monitoring system for Veritas smart contract, providing real-time insights, alerts, and performance metrics.

## Components

### Scripts
- `event_monitor.sh` - Monitors contract events
- `transaction_monitor.sh` - Tracks transaction patterns
- `performance_monitor.sh` - Measures performance metrics
- `alert_system.sh` - Sends notifications for anomalies
- `start_monitoring.sh` - Starts all monitoring services
- `stop_monitoring.sh` - Stops all monitoring services
- `rotate_logs.sh` - Manages log rotation

### Configuration
- `monitoring_config.yaml` - Main monitoring configuration
- Dashboard - Web-based monitoring interface

## Usage

### Start Monitoring
```bash
./start_monitoring.sh <CONTRACT_ADDRESS> <NETWORK>
```

### Stop Monitoring
```bash
./stop_monitoring.sh
```

### View Dashboard
Open `dashboard/dashboard.html` in your browser

## Alert Types

- **Security**: Admin activity, unusual patterns
- **Performance**: Gas usage, response times
- **Operational**: Failed transactions, errors

## Log Files

- `events_YYYYMMDD.log` - Event monitoring logs
- `transactions_YYYYMMDD.log` - Transaction monitoring logs
- `performance_YYYYMMDD.log` - Performance metrics
- `alerts_YYYYMMDD.log` - Alert notifications

## Configuration

Edit `monitoring_config.yaml` to customize:
- Alert thresholds
- Monitoring intervals
- Notification channels
- Data retention policies
