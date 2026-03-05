#!/bin/bash

# Start All Monitoring Services
CONTRACT_ADDRESS=$1
NETWORK=$2

if [ -z "$CONTRACT_ADDRESS" ] || [ -z "$NETWORK" ]; then
    echo "Usage: ./start_monitoring.sh <CONTRACT_ADDRESS> <NETWORK>"
    exit 1
fi

echo "🚀 Starting Veritas Monitoring Services"
echo "===================================="
echo "Contract: $CONTRACT_ADDRESS"
echo "Network: $NETWORK"
echo ""

# Start monitoring services in background
echo "Starting event monitoring..."
./scripts/event_monitor.sh $CONTRACT_ADDRESS $NETWORK &

echo "Starting transaction monitoring..."
./scripts/transaction_monitor.sh $CONTRACT_ADDRESS $NETWORK &

echo "Starting performance monitoring..."
./scripts/performance_monitor.sh $CONTRACT_ADDRESS $NETWORK &

echo "Starting alert system..."
./scripts/alert_system.sh &

echo "Opening monitoring dashboard..."
open dashboard/dashboard.html

echo ""
echo "✅ All monitoring services started!"
echo "📊 Dashboard available at: dashboard/dashboard.html"
echo "📋 Logs directory: logs/"
echo "🚨 Alerts directory: alerts/"
echo ""
echo "Stop monitoring with: ./stop_monitoring.sh"
