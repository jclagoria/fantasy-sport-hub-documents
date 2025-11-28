#!/bin/bash

# Kafka Test Consumer Script
# Consumes messages from topics to verify they're working

BOOTSTRAP_SERVERS="localhost:19092,localhost:19093,localhost:19094"

echo "=========================================="
echo "Kafka Test Consumer"
echo "=========================================="
echo ""
echo "Select a topic to consume from:"
echo "1. match.events"
echo "2. scoring.player-updates"
echo "3. trade.lifecycle"
echo "4. league.updates"
echo "5. notifications.outbox"
echo "6. user.actions"
echo ""
read -p "Enter topic number (1-6): " choice

case $choice in
    1) TOPIC="match.events" ;;
    2) TOPIC="scoring.player-updates" ;;
    3) TOPIC="trade.lifecycle" ;;
    4) TOPIC="league.updates" ;;
    5) TOPIC="notifications.outbox" ;;
    6) TOPIC="user.actions" ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Consuming messages from $TOPIC (Ctrl+C to stop)..."
echo "=========================================="
echo ""

kafka-console-consumer \
    --bootstrap-server $BOOTSTRAP_SERVERS \
    --topic $TOPIC \
    --from-beginning \
    --property print.timestamp=true \
    --property print.key=true \
    --property print.partition=true \
    --property print.offset=true
