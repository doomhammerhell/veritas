#!/bin/bash

# Alert System for Veritas Contract Monitoring
ALERT_THRESHOLD=${1:-"medium"}

echo "🚨 Alert System Started"
echo "======================"
echo "Alert threshold: $ALERT_THRESHOLD"
echo ""

ALERT_LOG="monitoring/logs/alerts_$(date +%Y%m%d).log"
ALERT_CONFIG="monitoring/configs/monitoring_config.yaml"

# Function to send alerts
send_alert() {
    local severity=$1
    local message=$2
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [$severity] ALERT: $message" >> $ALERT_LOG
    
    # Send to different channels based on severity
    case $severity in
        "critical")
            echo "🚨 CRITICAL: $message"
            # Send to all channels
            ;;
        "high")
            echo "⚠️  HIGH: $message"
            # Send to email and Discord
            ;;
        "medium")
            echo "📋 MEDIUM: $message"
            # Send to email
            ;;
        "low")
            echo "ℹ️  LOW: $message"
            # Send to Slack
            ;;
    esac
}

# Monitor for alert conditions
while true; do
    # Check for high admin activity
    admin_calls=$(grep -c "admin_function" monitoring/logs/transactions_$(date +%Y%m%d).log 2>/dev/null || echo "0")
    if [ "$admin_calls" -gt 5 ]; then
        send_alert "high" "High admin activity detected: $admin_calls calls in last hour"
    fi
    
    # Check for failed transactions
    failed_tx=$(grep -c "failed" monitoring/logs/transactions_$(date +%Y%m%d).log 2>/dev/null || echo "0")
    if [ "$failed_tx" -gt 10 ]; then
        send_alert "medium" "High failed transaction rate: $failed_tx failed transactions"
    fi
    
    # Check for unusual voting patterns
    vote_rate=$(grep -c "commit_vote" monitoring/logs/transactions_$(date +%Y%m%d).log 2>/dev/null || echo "0")
    if [ "$vote_rate" -gt 100 ]; then
        send_alert "medium" "Unusual voting pattern: $vote_rate commits detected"
    fi
    
    sleep 300  # Check every 5 minutes
done
