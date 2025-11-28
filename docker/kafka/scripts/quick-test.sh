#!/bin/bash

# Quick Kafka Test Script - Send one message to each topic

BOOTSTRAP_SERVERS="kafka-1:9092,kafka-2:9093,kafka-3:9094"

echo "=========================================="
echo "Quick Kafka Test - Sending test messages"
echo "=========================================="

# Function to send message
send_message() {
    local topic=$1
    local message=$2

    echo ""
    echo "Sending to $topic..."
    echo "$message" | kafka-console-producer \
        --bootstrap-server $BOOTSTRAP_SERVERS \
        --topic $topic \
        --property "parse.key=false" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Message sent to $topic"
    else
        echo "❌ Failed to send to $topic"
    fi
}

# 1. match.events
send_message "match.events" '{"eventId":"e1","matchId":"m1","sportId":"football","providerId":"api-football","timestamp":"2025-11-10T10:00:00Z","eventType":"GOL","playerId":"p1","teamId":"t1","minute":45,"metadata":{}}'

# 2. scoring.player-updates
send_message "scoring.player-updates" '{"updateId":"u1","playerId":"p1","matchId":"m1","leagueId":"l1","weekId":"w1","pointsAdded":5.0,"totalPoints":25.0,"eventType":"GOL","timestamp":"2025-11-10T10:00:00Z","isBonus":false}'

# 3. trade.lifecycle
send_message "trade.lifecycle" '{"eventId":"t1","tradeId":"trade1","leagueId":"l1","eventType":"PROPOSED","offeringTeamId":"team1","receivingTeamId":"team2","offeredPlayers":["p1","p2"],"requestedPlayers":["p3","p4"],"timestamp":"2025-11-10T10:00:00Z","metadata":{}}'

# 4. league.updates
send_message "league.updates" '{"eventId":"lu1","leagueId":"l1","eventType":"CREATED","timestamp":"2025-11-10T10:00:00Z","changes":{},"initiatedBy":"user1"}'

# 5. notifications.outbox
send_message "notifications.outbox" '{"notificationId":"n1","userId":"u1","type":"EMAIL","channel":"email","subject":"Test Notification","body":"This is a test","priority":"NORMAL","timestamp":"2025-11-10T10:00:00Z","metadata":{}}'

# 6. user.actions
send_message "user.actions" '{"actionId":"a1","userId":"u1","actionType":"LOGIN","timestamp":"2025-11-10T10:00:00Z","metadata":{}}'

echo ""
echo "=========================================="
echo "✅ Test complete! All messages sent."
echo "=========================================="
echo ""
echo "To verify messages were received, run:"
echo "  ./test-consumer.sh"
echo ""
