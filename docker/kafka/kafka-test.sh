#!/bin/bash

# Kafka Quick Test Helper
# Simple wrapper for testing Kafka from host machine

set -e

COMMAND=$1
TOPIC=$2

show_usage() {
    echo "Usage: ./kafka-test.sh [command] [topic]"
    echo ""
    echo "Commands:"
    echo "  produce [topic]  - Send a test message to a topic"
    echo "  consume [topic]  - Read messages from a topic"
    echo "  list            - List all topics"
    echo "  describe [topic] - Describe a topic"
    echo "  groups          - List consumer groups"
    echo ""
    echo "Available topics:"
    echo "  - match.events"
    echo "  - scoring.player-updates"
    echo "  - trade.lifecycle"
    echo "  - league.updates"
    echo "  - notifications.outbox"
    echo "  - user.actions"
    echo ""
    echo "Examples:"
    echo "  ./kafka-test.sh produce trade.lifecycle"
    echo "  ./kafka-test.sh consume match.events"
    echo "  ./kafka-test.sh list"
}

if [ -z "$COMMAND" ]; then
    show_usage
    exit 1
fi

case $COMMAND in
    produce)
        if [ -z "$TOPIC" ]; then
            echo "Error: Topic name required"
            show_usage
            exit 1
        fi

        # Sample messages for each topic
        case $TOPIC in
            match.events)
                MESSAGE='{"eventId":"e1","matchId":"m1","sportId":"football","providerId":"api-football","timestamp":"2025-11-10T10:00:00Z","eventType":"GOL","playerId":"p1","teamId":"t1","minute":45,"metadata":{}}'
                ;;
            scoring.player-updates)
                MESSAGE='{"updateId":"u1","playerId":"p1","matchId":"m1","leagueId":"l1","weekId":"w1","pointsAdded":5.0,"totalPoints":25.0,"eventType":"GOL","timestamp":"2025-11-10T10:00:00Z","isBonus":false}'
                ;;
            trade.lifecycle)
                MESSAGE='{"eventId":"t1","tradeId":"trade1","leagueId":"l1","eventType":"PROPOSED","offeringTeamId":"team1","receivingTeamId":"team2","offeredPlayers":["p1","p2"],"requestedPlayers":["p3","p4"],"timestamp":"2025-11-10T10:00:00Z","metadata":{}}'
                ;;
            league.updates)
                MESSAGE='{"eventId":"lu1","leagueId":"l1","eventType":"CREATED","timestamp":"2025-11-10T10:00:00Z","changes":{},"initiatedBy":"user1"}'
                ;;
            notifications.outbox)
                MESSAGE='{"notificationId":"n1","userId":"u1","type":"EMAIL","channel":"email","subject":"Test Notification","body":"This is a test","priority":"NORMAL","timestamp":"2025-11-10T10:00:00Z","metadata":{}}'
                ;;
            user.actions)
                MESSAGE='{"actionId":"a1","userId":"u1","actionType":"LOGIN","timestamp":"2025-11-10T10:00:00Z","metadata":{}}'
                ;;
            *)
                echo "Unknown topic: $TOPIC"
                exit 1
                ;;
        esac

        echo "Sending message to $TOPIC..."
        if command -v jq &> /dev/null; then
            echo "$MESSAGE" | jq '.'
        else
            echo "$MESSAGE"
        fi
        echo ""

        docker exec fantasy-kafka-1 bash -c "echo '$MESSAGE' | kafka-console-producer --bootstrap-server kafka-1:9092 --topic $TOPIC"

        if [ $? -eq 0 ]; then
            echo "✅ Message sent successfully to $TOPIC"
        else
            echo "❌ Failed to send message"
            exit 1
        fi
        ;;

    consume)
        if [ -z "$TOPIC" ]; then
            echo "Error: Topic name required"
            show_usage
            exit 1
        fi

        echo "Reading messages from $TOPIC (Press Ctrl+C to stop)..."
        echo ""

        docker exec fantasy-kafka-1 kafka-console-consumer \
            --bootstrap-server kafka-1:9092 \
            --topic $TOPIC \
            --from-beginning \
            --property print.timestamp=true \
            --property print.key=true \
            --property print.partition=true \
            --property print.offset=true
        ;;

    list)
        echo "Listing all topics..."
        docker exec fantasy-kafka-1 kafka-topics --list --bootstrap-server kafka-1:9092
        ;;

    describe)
        if [ -z "$TOPIC" ]; then
            echo "Error: Topic name required"
            show_usage
            exit 1
        fi

        echo "Describing topic: $TOPIC"
        docker exec fantasy-kafka-1 kafka-topics --describe --bootstrap-server kafka-1:9092 --topic $TOPIC
        ;;

    groups)
        echo "Listing consumer groups..."
        docker exec fantasy-kafka-1 kafka-consumer-groups --list --bootstrap-server kafka-1:9092
        ;;

    *)
        echo "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
