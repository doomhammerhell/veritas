#!/bin/bash

# Stop All Monitoring Services
echo "🛑 Stopping Veritas Monitoring Services"
echo "======================================"

# Kill all monitoring processes
pkill -f "event_monitor.sh"
pkill -f "transaction_monitor.sh"
pkill -f "performance_monitor.sh"
pkill -f "alert_system.sh"

echo "✅ All monitoring services stopped"
