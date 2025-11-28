#!/bin/bash

# Kafka Test Producer Script
# Sends sample events to verify topics are working

BOOTSTRAP_SERVERS="localhost:19092,localhost:19093,localhost:19094"

echo "=========================================="
echo "Kafka Test Producer"
echo "=========================================="
echo ""
echo "Select a topic to test:"
echo "1. match.events"
echo "2. scoring.player-updates"
echo "3. trade.lifecycle"
echo "4. league.updates"
echo "5. notifications.outbox"
echo "6. user.actions"
echo ""
read -p "Enter topic number (1-6): " choice

case $choice in
    1)
        TOPIC="match.events"
        MESSAGE='{"eventId":"e1","matchId":"m1","sportId":"football","providerId":"api-football","timestamp":"2025-11-10T10:00:00Z","eventType":"GOL","playerId":"p1","teamId":"t1","minute":45,"metadata":{}}'
        ;;
    2)
        TOPIC="scoring.player-updates"
        MESSAGE='{"updateId":"u1","playerId":"p1","matchId":"m1","leagueId":"l1","weekId":"w1","pointsAdded":5.0,"totalPoints":25.0,"eventType":"GOL","timestamp":"2025-11-10T10:00:00Z","isBonus":false}'
        ;;
    3)
        TOPIC="trade.lifecycle"
        MESSAGE='{"eventId":"t1","tradeId":"trade1","leagueId":"l1","eventType":"PROPOSED","offeringTeamId":"team1","receivingTeamId":"team2","offeredPlayers":["p1","p2"],"requestedPlayers":["p3","p4"],"timestamp":"2025-11-10T10:00:00Z","metadata":{}}'
        ;;
    4)
        TOPIC="league.updates"
        MESSAGE='{"eventId":"lu1","leagueId":"l1","eventType":"CREATED","timestamp":"2025-11-10T10:00:00Z","changes":{},"initiatedBy":"user1"}'
        ;;
    5)
        TOPIC="notifications.outbox"
        MESSAGE='{"notificationId":"n1","userId":"u1","type":"EMAIL","channel":"email","subject":"Test Notification","body":"This is a test","priority":"NORMAL","timestamp":"2025-11-10T10:00:00Z","metadata":{}}'
        ;;
    6)
        TOPIC="user.actions"
        MESSAGE='{"actionId":"a1","userId":"u1","actionType":"LOGIN","timestamp":"2025-11-10T10:00:00Z","metadata":{}}'
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Sending message to $TOPIC:"
echo "$MESSAGE"
echo ""

echo "$MESSAGE" | kafka-console-producer \
    --bootstrap-server $BOOTSTRAP_SERVERS \
    --topic $TOPIC \
    --property "parse.key=false"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Message sent successfully to $TOPIC"
else
    echo ""
    echo "❌ Failed to send message"
fi
