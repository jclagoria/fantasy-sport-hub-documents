# Kafka Local Development Setup

Local Kafka cluster for Fantasy Sports Hub development, configured according to [09_KAFKA_TOPOLOGY.md](../claudedocs/09_KAFKA_TOPOLOGY.md).

## Architecture

**Cluster Configuration:**
- 3 Kafka brokers (replication factor: 3)
- 1 Zookeeper instance
- Kafka UI for cluster management
- 6 pre-configured topics

**Topics Created:**

| Topic | Partitions | Retention | Purpose |
|-------|-----------|-----------|---------|
| `match.events` | 24 | 7 days | Live match events stream |
| `scoring.player-updates` | 12 | 3 days | Player scoring updates |
| `trade.lifecycle` | 6 | 30 days | Trade lifecycle events |
| `league.updates` | 3 | 30 days | League configuration updates |
| `notifications.outbox` | 6 | 1 day | Notification outbox pattern |
| `user.actions` | 6 | 7 days | User action events |

## Quick Start

### 1. Start Kafka Cluster

```bash
# Start all services (Zookeeper + 3 Kafka brokers + UI + topic initialization)
docker-compose -f docker-compose.kafka.yml up -d

# Check service health
docker-compose -f docker-compose.kafka.yml ps

# View logs
docker-compose -f docker-compose.kafka.yml logs -f
```

### 2. Access Kafka UI

Open [http://localhost:8080](http://localhost:8080) in your browser to access the Kafka UI management interface.

**Features:**
- Topic browsing and message viewing
- Consumer group monitoring
- Broker health status
- Message production/consumption testing

### 3. Verify Topics

```bash
# List all topics
docker exec fantasy-kafka-1 kafka-topics --list --bootstrap-server kafka-1:9092

# Describe a specific topic
docker exec fantasy-kafka-1 kafka-topics --describe --bootstrap-server kafka-1:9092 --topic match.events

# Check consumer groups
docker exec fantasy-kafka-1 kafka-consumer-groups --list --bootstrap-server kafka-1:9092
```

## Testing

### Using Helper Script (Easiest)

A simple helper script [kafka-test.sh](kafka-test.sh) is provided for quick testing:

```bash
# Send test message to a topic
./kafka-test.sh produce trade.lifecycle
./kafka-test.sh produce match.events

# Read messages from a topic
./kafka-test.sh consume trade.lifecycle

# List all topics
./kafka-test.sh list

# Describe a topic
./kafka-test.sh describe match.events

# List consumer groups
./kafka-test.sh groups

# Show help
./kafka-test.sh
```

### Quick Test (Direct Commands)

**Send a test message:**
```bash
# Test trade.lifecycle topic
docker exec fantasy-kafka-1 bash -c 'echo "{\"eventId\":\"t1\",\"tradeId\":\"trade1\",\"leagueId\":\"l1\",\"eventType\":\"PROPOSED\",\"offeringTeamId\":\"team1\",\"receivingTeamId\":\"team2\",\"offeredPlayers\":[\"p1\",\"p2\"],\"requestedPlayers\":[\"p3\",\"p4\"],\"timestamp\":\"2025-11-10T10:00:00Z\",\"metadata\":{}}" | kafka-console-producer --bootstrap-server kafka-1:9092 --topic trade.lifecycle'

# Test match.events topic
docker exec fantasy-kafka-1 bash -c 'echo "{\"eventId\":\"e1\",\"matchId\":\"m1\",\"sportId\":\"football\",\"providerId\":\"api-football\",\"timestamp\":\"2025-11-10T10:00:00Z\",\"eventType\":\"GOL\",\"playerId\":\"p1\",\"teamId\":\"t1\",\"minute\":45,\"metadata\":{}}" | kafka-console-producer --bootstrap-server kafka-1:9092 --topic match.events'
```

**Read messages:**
```bash
# Read from trade.lifecycle (first message only)
docker exec fantasy-kafka-1 kafka-console-consumer \
  --bootstrap-server kafka-1:9092 \
  --topic trade.lifecycle \
  --from-beginning \
  --max-messages 1

# Read from match.events (all messages, Ctrl+C to stop)
docker exec fantasy-kafka-1 kafka-console-consumer \
  --bootstrap-server kafka-1:9092 \
  --topic match.events \
  --from-beginning
```

### Interactive Testing Inside Container

> **IMPORTANT:** The test scripts in `kafka/scripts/` must be run from inside the Kafka container, not from your host machine. They require Kafka CLI tools that are only available inside the container.

#### Option 1: Enter container and use scripts interactively

```bash
# Enter container shell
docker exec -it fantasy-kafka-1 bash

# Inside container: Use kafka commands directly
kafka-console-producer --bootstrap-server kafka-1:9092 --topic match.events
# Type your JSON messages and press Enter after each one
# Press Ctrl+C to exit

# Or consume messages
kafka-console-consumer \
  --bootstrap-server kafka-1:9092 \
  --topic match.events \
  --from-beginning \
  --property print.timestamp=true \
  --property print.key=true
# Press Ctrl+C to exit
```

#### Option 2: Use the helper script from host (Recommended)

```bash
# The kafka-test.sh helper wraps Docker commands and works from host
./kafka-test.sh produce match.events
./kafka-test.sh consume match.events
./kafka-test.sh list
```

### Manual Testing

**Produce a message:**
```bash
docker exec -it fantasy-kafka-1 kafka-console-producer \
  --bootstrap-server kafka-1:9092 \
  --topic match.events

# Then type your JSON message and press Enter
{"eventId":"test1","matchId":"m1","sportId":"football","eventType":"GOL"}
```

**Consume messages:**
```bash
docker exec -it fantasy-kafka-1 kafka-console-consumer \
  --bootstrap-server kafka-1:9092 \
  --topic match.events \
  --from-beginning
```

## Connection Details

### From Host Machine (Application Development)

**Bootstrap Servers:**
```
localhost:19092,localhost:19093,localhost:19094
```

**Example Java Configuration:**
```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:19092,localhost:19093,localhost:19094");
props.put("acks", "all");
props.put("retries", Integer.MAX_VALUE);
props.put("enable.idempotence", true);
```

**Example Spring Boot (application.yml):**
```yaml
spring:
  kafka:
    bootstrap-servers: localhost:19092,localhost:19093,localhost:19094
    producer:
      acks: all
      retries: 2147483647
      properties:
        enable.idempotence: true
    consumer:
      auto-offset-reset: earliest
      enable-auto-commit: false
```

### From Docker Network (Inter-Container Communication)

**Bootstrap Servers:**
```
kafka-1:9092,kafka-2:9093,kafka-3:9094
```

**Docker Compose Example:**
```yaml
your-service:
  networks:
    - fantasy-kafka-network
  environment:
    KAFKA_BOOTSTRAP_SERVERS: kafka-1:9092,kafka-2:9093,kafka-3:9094
```

## Management Commands

### Topic Operations

```bash
# Create a new topic manually
docker exec fantasy-kafka-1 kafka-topics \
  --create \
  --bootstrap-server kafka-1:9092 \
  --topic my-new-topic \
  --partitions 6 \
  --replication-factor 3 \
  --config compression.type=snappy \
  --config min.insync.replicas=2

# Increase partitions (cannot decrease!)
docker exec fantasy-kafka-1 kafka-topics \
  --alter \
  --bootstrap-server kafka-1:9092 \
  --topic match.events \
  --partitions 48

# Delete a topic
docker exec fantasy-kafka-1 kafka-topics \
  --delete \
  --bootstrap-server kafka-1:9092 \
  --topic test-topic
```

### Consumer Group Management

```bash
# List consumer groups
docker exec fantasy-kafka-1 kafka-consumer-groups \
  --list \
  --bootstrap-server kafka-1:9092

# Describe consumer group (check lag)
docker exec fantasy-kafka-1 kafka-consumer-groups \
  --describe \
  --bootstrap-server kafka-1:9092 \
  --group scoring-engine

# Reset consumer group offset
docker exec fantasy-kafka-1 kafka-consumer-groups \
  --reset-offsets \
  --bootstrap-server kafka-1:9092 \
  --group my-group \
  --topic match.events \
  --to-earliest \
  --execute
```

## Monitoring

### Health Checks

```bash
# Check broker status
docker-compose -f docker-compose.kafka.yml ps

# View broker logs
docker-compose -f docker-compose.kafka.yml logs kafka-1

# Check cluster metadata
docker exec fantasy-kafka-1 kafka-metadata --bootstrap-server kafka-1:9092 --describe --all
```

### Performance Metrics

**Key Metrics to Monitor:**
- Consumer lag per partition
- Messages per second (throughput)
- Under-replicated partitions
- Broker disk usage
- Network I/O

**Access via Kafka UI:**
- Navigate to http://localhost:8080
- Select "fantasy-sports-cluster"
- View metrics under "Brokers" and "Topics" tabs

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose -f docker-compose.kafka.yml logs

# Restart services
docker-compose -f docker-compose.kafka.yml restart

# Clean restart (removes data!)
docker-compose -f docker-compose.kafka.yml down -v
docker-compose -f docker-compose.kafka.yml up -d
```

### Topics Not Created

If topics were not created automatically, you can manually create them by following these steps:

1. First, ensure the scripts directory exists in the container:

```bash
docker exec -it kafka-1 mkdir -p /scripts
```

2. Copy and execute the create-topics.sh script:

```bash
docker cp ./scripts/create-topics.sh kafka-1:/create-topics.sh
docker exec -it kafka-1 chmod +x /create-topics.sh
docker exec -it kafka-1 /create-topics.sh
```

### Connection Refused

**From Host:**
- Use ports 19092, 19093, 19094
- Check `PLAINTEXT_HOST` listeners are configured

**From Docker:**
- Use internal ports 9092, 9093, 9094
- Ensure service is on `fantasy-kafka-network`

### Consumer Lag

```bash
# Check consumer group lag
docker exec fantasy-kafka-1 kafka-consumer-groups \
  --describe \
  --bootstrap-server kafka-1:9092 \
  --group your-consumer-group

# Increase consumers if lag is high
# Scale your consumer group instances
```

## Data Persistence

**Volumes:**
- `fantasy-zookeeper-data`: Zookeeper data
- `fantasy-zookeeper-logs`: Zookeeper transaction logs
- `fantasy-kafka-1-data`: Broker 1 data
- `fantasy-kafka-2-data`: Broker 2 data
- `fantasy-kafka-3-data`: Broker 3 data

**Clean All Data:**
```bash
# WARNING: This deletes all messages and topics!
docker-compose -f docker-compose.kafka.yml down -v
```

**Backup Data:**
```bash
# Stop services
docker-compose -f docker-compose.kafka.yml stop

# Backup volumes
docker run --rm -v fantasy-kafka-1-data:/data -v $(pwd):/backup alpine tar czf /backup/kafka-1-backup.tar.gz /data

# Restart services
docker-compose -f docker-compose.kafka.yml start
```

## Shutdown

```bash
# Stop all services
docker-compose -f docker-compose.kafka.yml stop

# Stop and remove containers (keeps data)
docker-compose -f docker-compose.kafka.yml down

# Stop and remove everything including volumes (deletes data!)
docker-compose -f docker-compose.kafka.yml down -v
```

## Production Differences

This local setup differs from production in:

| Aspect | Local | Production |
|--------|-------|------------|
| Brokers | 3 (single host) | 3+ (distributed) |
| Replication | 3 | 3+ |
| Security | None | SASL/SSL |
| Monitoring | Kafka UI | Prometheus + Grafana |
| Backup | Manual | Automated |
| Network | Bridge | Cloud networking |

## Resources

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Platform](https://docs.confluent.io/platform/current/overview.html)
- [Project Topology](../claudedocs/09_KAFKA_TOPOLOGY.md)
- [Kafka UI GitHub](https://github.com/provectus/kafka-ui)

## Support

For issues or questions:
1. Check service logs: `docker-compose logs`
2. Verify network connectivity
3. Review topology documentation
4. Check Kafka UI for cluster health
