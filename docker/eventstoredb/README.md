# EventStoreDB Docker Setup

Docker Compose configuration for EventStoreDB Streams, implementing the event sourcing architecture for the Fantasy Sports Hub.

## 📋 Overview

This setup provides a production-ready EventStoreDB instance with:

- **Stream Categories**: Match, Player, Team, League, Security, Fraud Detection
- **Event Storage**: 500M events/year capacity (~500GB compressed)
- **Projections**: Real-time aggregations for match scoring, player statistics, security audit
- **Data Retention**: 5 years for sports data, 2 years for audit logs
- **Performance Tuning**: Optimized for high-throughput event ingestion

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Copy environment configuration
cp .env .env.local

# Edit configuration (optional)
nano .env.local
```

### 2. Start EventStoreDB

```bash
# Start EventStoreDB
docker-compose -f docker-compose.eventstoredb.yml up -d

# Check logs
docker-compose -f docker-compose.eventstoredb.yml logs -f eventstoredb

# Wait for health check
docker-compose -f docker-compose.eventstoredb.yml ps
```

### 3. Initialize Streams and Projections

```bash
# Run initialization script
./scripts/eventstoredb/init-streams.sh

# Verify projections
curl -u admin:changeit http://localhost:2113/projections/any
```

### 4. Access Admin UI

Open browser: http://localhost:2113

**Default Credentials:**
- Username: `admin`
- Password: `changeit` (change in production!)

## 📊 Stream Architecture

### Stream Naming Convention

| Stream Pattern | Purpose | Events | Retention |
|---------------|---------|---------|-----------|
| `match-{matchId}` | Match events | PlayerScored, PlayerAssisted, MatchStarted, MatchEnded | 5 years |
| `player-{playerId}` | Player events | All player-specific events | 5 years |
| `team-{teamId}` | Team events | Team transactions, roster changes | 5 years |
| `league-{leagueId}` | League events | League-wide events | 5 years |
| `security-audit` | Security events | LoginAttempt, LoginFailed, UnauthorizedAccess | 2 years |
| `fraud-detection` | Fraud events | SuspiciousTransaction, MultiAccountDetected | 2 years |

### Event Types

**Match Events:**
```typescript
PlayerScored {
  eventId: UUID
  matchId: UUID
  playerId: UUID
  sportId: string
  timestamp: Instant
  minute: int
  providerId: string
  metadata: object
}

PlayerAssisted { ... }
PlayerCarded { cardType: 'YELLOW' | 'RED', ... }
MatchStarted { ... }
MatchEnded { ... }
```

**Scoring Events:**
```typescript
LiveScoreCalculated {
  eventId: UUID
  matchId: UUID
  playerId: UUID
  teamId: UUID
  points: int
  ruleApplied: string
  timestamp: Instant
}

BonusAwarded {
  eventId: UUID
  playerId: UUID
  teamId: UUID
  bonusType: string
  points: int
  description: string
  timestamp: Instant
}
```

**Security Events:**
```typescript
LoginAttempt { userId, ipAddress, timestamp, ... }
LoginFailed { userId, ipAddress, reason, timestamp, ... }
LoginSuccessful { userId, ipAddress, timestamp, ... }
UnauthorizedAccess { userId, resource, ipAddress, timestamp, ... }
```

## 🔧 Projections

### Match Scoring Projection

Aggregates player events for real-time scoring:

```javascript
// Projection: match-scoring
// Input: $ce-match (all match events)
// Output: Aggregated match state with player scores
```

**State Output:**
```json
{
  "matchId": "match-123",
  "status": "IN_PROGRESS",
  "playerEvents": {
    "player-messi": {
      "goals": 2,
      "assists": 1,
      "totalPoints": 25
    }
  }
}
```

### Player Statistics Projection

Tracks season-long player performance:

```javascript
// Projection: player-statistics
// Input: $ce-player (all player events)
// Output: Season statistics and averages
```

**State Output:**
```json
{
  "playerId": "player-messi",
  "season": "2025",
  "gamesPlayed": 38,
  "totalPoints": 456,
  "averagePointsPerGame": 12.0,
  "eventCounts": {
    "GOL": 28,
    "ASISTENCIA": 15
  }
}
```

### Security Audit Projection

Monitors authentication and access patterns:

```javascript
// Projection: security-audit
// Input: security-audit stream
// Output: Security metrics and suspicious activity
```

**State Output:**
```json
{
  "totalAttempts": 1000,
  "failedAttempts": 50,
  "suspiciousIPs": {
    "192.168.1.100": {
      "failedAttempts": 10,
      "lastFailureAt": "2025-11-10T12:00:00Z"
    }
  }
}
```

## 📝 Usage Examples

### Writing Events

**Using HTTP API:**
```bash
# Write PlayerScored event
curl -i -X POST "http://localhost:2113/streams/match-123/incoming" \
  -u admin:changeit \
  -H "Content-Type: application/vnd.eventstore.events+json" \
  -d '[{
    "eventId": "'"$(uuidgen)"'",
    "eventType": "PlayerScored",
    "data": {
      "matchId": "match-123",
      "playerId": "player-messi",
      "sportId": "FUTBOL",
      "timestamp": "2025-11-10T15:23:00Z",
      "minute": 23,
      "providerId": "api-football"
    }
  }]'
```

**Using gRPC Client (Node.js example):**
```javascript
import { EventStoreDBClient, jsonEvent } from '@eventstore/db-client';

const client = EventStoreDBClient.connectionString(
  'esdb://admin:changeit@localhost:2113?tls=false'
);

const event = jsonEvent({
  type: 'PlayerScored',
  data: {
    matchId: 'match-123',
    playerId: 'player-messi',
    sportId: 'FUTBOL',
    timestamp: new Date().toISOString(),
    minute: 23,
    providerId: 'api-football'
  }
});

await client.appendToStream('match-123', event);
```

### Reading Events

**Read stream:**
```bash
curl -H "Accept: application/vnd.eventstore.atom+json" \
  -u admin:changeit \
  "http://localhost:2113/streams/match-123"
```

**Read projection state:**
```bash
curl -u admin:changeit \
  "http://localhost:2113/projection/match-scoring/state?partition=match-123"
```

### Managing Projections

**List all projections:**
```bash
curl -u admin:changeit http://localhost:2113/projections/any
```

**Enable/Disable projection:**
```bash
# Enable
curl -X POST -u admin:changeit \
  "http://localhost:2113/projection/match-scoring/command/enable"

# Disable
curl -X POST -u admin:changeit \
  "http://localhost:2113/projection/match-scoring/command/disable"
```

**Reset projection:**
```bash
curl -X POST -u admin:changeit \
  "http://localhost:2113/projection/match-scoring/command/reset"
```

## 🔒 Security Configuration

### Production Security Checklist

- [ ] Change default admin password
- [ ] Enable TLS/SSL encryption
- [ ] Configure authentication and authorization
- [ ] Set up firewall rules (only allow necessary ports)
- [ ] Enable audit logging
- [ ] Configure network isolation

### Change Admin Password

```bash
# Update .env.eventstoredb.local
EVENTSTOREDB_ADMIN_PASSWORD=your-secure-password

# Restart container
docker-compose -f docker-compose.eventstoredb.yml restart
```

### Enable TLS (Production)

```yaml
# docker-compose.eventstoredb.yml
environment:
  - EVENTSTORE_INSECURE=false
  - EVENTSTORE_CERTIFICATE_FILE=/etc/eventstore/certs/node.crt
  - EVENTSTORE_CERTIFICATE_PRIVATE_KEY_FILE=/etc/eventstore/certs/node.key

volumes:
  - ./certs:/etc/eventstore/certs:ro
```

## 📈 Monitoring

### Health Checks

```bash
# Liveness check
curl http://localhost:2113/health/live

# Readiness check
curl http://localhost:2113/health/ready

# Full health info
curl -u admin:changeit http://localhost:2113/info
```

### Metrics

EventStoreDB exposes metrics at: `http://localhost:2113/stats`

**Key Metrics:**
- `es-queue-{queue-name}-length`: Queue sizes
- `es-writer-lastFlushSize`: Write throughput
- `es-proc-mem`: Memory usage
- `es-disk-io`: Disk I/O performance

### Container Stats

```bash
# Real-time stats
docker stats fantasysport-eventstoredb

# Resource usage
docker-compose -f docker-compose.eventstoredb.yml exec eventstoredb \
  sh -c "du -sh /var/lib/eventstore"
```

## 🗄️ Backup and Recovery

### Backup Strategy

```bash
# Create backup script
cat > scripts/eventstoredb/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="./backups/eventstoredb/$(date +%Y%m%d_%H%M%S)"
mkdir -p "${BACKUP_DIR}"

# Stop container for consistent backup
docker-compose -f docker-compose.eventstoredb.yml stop eventstoredb

# Backup data directory
tar -czf "${BACKUP_DIR}/eventstore-data.tar.gz" ./data/eventstoredb

# Restart container
docker-compose -f docker-compose.eventstoredb.yml start eventstoredb

echo "Backup completed: ${BACKUP_DIR}"
EOF

chmod +x scripts/eventstoredb/backup.sh
```

### Restore from Backup

```bash
# Stop container
docker-compose -f docker-compose.eventstoredb.yml stop eventstoredb

# Restore data
tar -xzf backups/eventstoredb/20251110_120000/eventstore-data.tar.gz \
  -C ./data/

# Start container
docker-compose -f docker-compose.eventstoredb.yml start eventstoredb
```

## 🔧 Maintenance

### Scavenging (Data Cleanup)

EventStoreDB automatically scavenges old events based on retention policies.

**Manual scavenge:**
```bash
curl -X POST -u admin:changeit \
  "http://localhost:2113/admin/scavenge?startFromChunk=0"
```

### Index Rebuilding

```bash
# Rebuild indexes
curl -X POST -u admin:changeit \
  "http://localhost:2113/admin/reindex"
```

### Log Rotation

Logs are stored in `./logs/eventstoredb/`. Configure log rotation:

```bash
# Create logrotate config
cat > /etc/logrotate.d/eventstoredb << EOF
./logs/eventstoredb/*.log {
  daily
  rotate 30
  compress
  delaycompress
  notifempty
  missingok
}
EOF
```

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose -f docker-compose.eventstoredb.yml logs eventstoredb

# Check data directory permissions
ls -la ./data/eventstoredb

# Reset data (WARNING: deletes all events)
rm -rf ./data/eventstoredb/*
docker-compose -f docker-compose.eventstoredb.yml up -d
```

### Projection Errors

```bash
# Check projection status
curl -u admin:changeit \
  "http://localhost:2113/projection/match-scoring/statistics"

# View projection errors
curl -u admin:changeit \
  "http://localhost:2113/projection/match-scoring/state"
```

### Performance Issues

```bash
# Check resource usage
docker stats fantasysport-eventstoredb

# Increase memory limit in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 8G  # Increase from 4G
```

## 📚 Resources

- [EventStoreDB Documentation](https://developers.eventstore.com/)
- [EventStoreDB Client SDKs](https://developers.eventstore.com/clients/)
- [Projection Documentation](https://developers.eventstore.com/server/v23.10/projections.html)
- [Operations Guide](https://developers.eventstore.com/server/v23.10/operations.html)

## 🤝 Support

For issues and questions:
- EventStoreDB GitHub: https://github.com/EventStore/EventStore
- Community Forum: https://discuss.eventstore.com/
- Stack Overflow: [eventstoredb tag]

---

**Version**: 1.0.0
**Last Updated**: 2025-11-10
**EventStoreDB Version**: 23.10.0
