#!/bin/bash

# Kafka Topic Creation Script
# Based on claudedocs/09_KAFKA_TOPOLOGY.md

BOOTSTRAP_SERVERS="kafka-1:9092,kafka-2:9093,kafka-3:9094"
REPLICATION_FACTOR=3
MIN_IN_SYNC_REPLICAS=2
COMPRESSION_TYPE="snappy"

echo "=========================================="
echo "Creating Kafka Topics for Fantasy Sports Hub"
echo "=========================================="

# Function to create topic
create_topic() {
    local topic_name=$1
    local partitions=$2
    local retention_ms=$3

    echo ""
    echo "Creating topic: $topic_name"
    echo "  - Partitions: $partitions"
    echo "  - Replication Factor: $REPLICATION_FACTOR"
    echo "  - Retention: $retention_ms ms"

    kafka-topics --create \
        --bootstrap-server $BOOTSTRAP_SERVERS \
        --topic $topic_name \
        --partitions $partitions \
        --replication-factor $REPLICATION_FACTOR \
        --config compression.type=$COMPRESSION_TYPE \
        --config min.insync.replicas=$MIN_IN_SYNC_REPLICAS \
        --config retention.ms=$retention_ms \
        --if-not-exists

    if [ $? -eq 0 ]; then
        echo "✅ Topic $topic_name created successfully"
    else
        echo "❌ Failed to create topic $topic_name"
    fi
}

# 0. raw-sports-events - Raw sports events data
create_topic "raw-sports-events" 10 604800000  # 10 partitions, 7 days

# 1. match.events - Live match events stream
create_topic "match.events" 24 604800000  # 7 days

# 2. scoring.player-updates - Player scoring updates
create_topic "scoring.player-updates" 12 259200000  # 3 days

# 3. trade.lifecycle - Trade lifecycle events
create_topic "trade.lifecycle" 6 2592000000  # 30 days

# 4. league.updates - League configuration updates
create_topic "league.updates" 3 2592000000  # 30 days

# 5. notifications.outbox - Notification outbox pattern
create_topic "notifications.outbox" 6 86400000  # 1 day

# 6. user.actions - User action events (referenced in doc)
create_topic "user.actions" 6 604800000  # 7 days

echo ""
echo "=========================================="
echo "Listing all topics:"
echo "=========================================="
kafka-topics --list --bootstrap-server $BOOTSTRAP_SERVERS

echo ""
echo "=========================================="
echo "Topic Details:"
echo "=========================================="
for topic in "match.events" "scoring.player-updates" "trade.lifecycle" "league.updates" "notifications.outbox" "user.actions"
do
    echo ""
    echo "Topic: $topic"
    kafka-topics --describe --bootstrap-server $BOOTSTRAP_SERVERS --topic $topic
done

echo ""
echo "=========================================="
echo "✅ Kafka topics setup completed!"
echo "=========================================="
