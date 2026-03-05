#!/bin/bash

# Log Rotation Script
LOG_DIR="monitoring/logs"
RETENTION_DAYS=30

echo "🔄 Rotating logs older than $RETENTION_DAYS days..."

# Find and remove old log files
find $LOG_DIR -name "*.log" -mtime +$RETENTION_DAYS -delete

echo "✅ Log rotation completed"
