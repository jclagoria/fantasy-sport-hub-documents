# Event Schemas - Event Schemas

> **Schema Registry + Avro**: Schema evolution with backward compatibility

---

## 🎯 Schema Evolution Strategy

### Compatibility Modes

| Mode        | Description                         | Use Case |
|-------------|-------------------------------------|----------|
| **BACKWARD**| New schema can read old data        | Adding optional fields |
| **FORWARD** | Old schema can read new data        | Removing fields |
| **FULL**    | Both backward and forward compatible| Safest option |
| **NONE**    | No compatibility checks             | Breaking changes allowed |

**Chosen Strategy**: **FULL compatibility** for production events

---

## 📋 Event Catalog

### Domain Events

| Event Type            | Topic                   | Schema Version | Purpose |
|-----------------------|-------------------------|----------------|---------|
| `MatchEvent`          | `match.events`          | v2             | Live match events |
| `PlayerScoreUpdate`   | `scoring.player-updates`| v1             | Score calculations |
| `TradeLifecycleEvent` | `trade.lifecycle`       | v1             | Trade status changes |
| `LeagueEvent`         | `league.updates`        | v1             | League configuration |
| `UserActionEvent`     | `user.actions`          | v1             | User activity tracking |
| `NotificationEvent`   | `notifications.outbox`  | v1             | Notification requests |

---

## ⚽ Match Event Schema

### Avro Schema Definition

```json
{
  "type": "record",
  "name": "MatchEvent",
  "namespace": "com.fantasy.events.match",
  "version": 2,
  "doc": "Domain event representing a match occurrence",
  "fields": [
    {
      "name": "eventId",
      "type": "string",
      "doc": "Unique event identifier (UUID)"
    },
    {
      "name": "matchId",
      "type": "string",
      "doc": "Match identifier (UUID)"
    },
    {
      "name": "timestamp",
      "type": "long",
      "logicalType": "timestamp-millis",
      "doc": "Event occurrence timestamp"
    },
    {
      "name": "sportId",
      "type": "string",
      "doc": "Sport identifier (FUTBOL, BALONCESTO, etc.)"
    },
    {
      "name": "providerId",
      "type": "string",
      "doc": "Data provider identifier"
    },
    {
      "name": "eventType",
      "type": {
        "type": "enum",
        "name": "MatchEventType",
        "symbols": [
          "MATCH_STARTED",
          "MATCH_ENDED",
          "PERIOD_ENDED",
          "GOL",
          "ASISTENCIA",
          "YELLOW_CARD",
          "RED_CARD",
          "SUBSTITUTION",
          "FREE_THROW_MADE",
          "THREE_POINTER",
          "REBOUND",
          "BLOCK",
          "STEAL",
          "HOME_RUN",
          "STRIKEOUT",
          "STOLEN_BASE"
        ]
      },
      "doc": "Type of match event"
    },
    {
      "name": "playerId",
      "type": ["null", "string"],
      "default": null,
      "doc": "Player involved in event (UUID, nullable)"
    },
    {
      "name": "teamId",
      "type": ["null", "string"],
      "default": null,
      "doc": "Team involved in event (UUID, nullable)"
    },
    {
      "name": "minute",
      "type": ["null", "int"],
      "default": null,
      "doc": "Match minute when event occurred (nullable)"
    },
    {
      "name": "metadata",
      "type": {
        "type": "map",
        "values": "string"
      },
      "default": {},
      "doc": "Additional event-specific metadata"
    },
    {
      "name": "schemaVersion",
      "type": "int",
      "default": 2,
      "doc": "Schema version for evolution tracking"
    }
  ]
}
```

### Java Event Class

```java
/**
 * Match event domain object.
 * Generated from Avro schema.
 */
@AvroGenerated
public class MatchEvent {

    private String eventId;
    private String matchId;
    private Instant timestamp;
    private String sportId;
    private String providerId;
    private MatchEventType eventType;
    private String playerId;
    private String teamId;
    private Integer minute;
    private Map<String, String> metadata;
    private int schemaVersion;

    // Builder pattern
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private final MatchEvent event = new MatchEvent();

        public Builder eventId(String eventId) {
            event.eventId = eventId;
            return this;
        }

        public Builder matchId(String matchId) {
            event.matchId = matchId;
            return this;
        }

        public Builder timestamp(Instant timestamp) {
            event.timestamp = timestamp;
            return this;
        }

        public Builder eventType(MatchEventType eventType) {
            event.eventType = eventType;
            return this;
        }

        public Builder playerId(String playerId) {
            event.playerId = playerId;
            return this;
        }

        public Builder metadata(String key, String value) {
            if (event.metadata == null) {
                event.metadata = new HashMap<>();
            }
            event.metadata.put(key, value);
            return this;
        }

        public MatchEvent build() {
            event.schemaVersion = 2;
            return event;
        }
    }
}
```

### Schema Evolution Example

**Version 1 → Version 2**:
```json
{
  "changes": [
    {
      "type": "add_field",
      "field": "metadata",
      "default": {},
      "rationale": "Support extensibility for new event types"
    },
    {
      "type": "add_enum_value",
      "enum": "MatchEventType",
      "value": "STOLEN_BASE",
      "rationale": "Support baseball events"
    }
  ],
  "compatibility": "FULL",
  "migration": "Automatic - old consumers ignore new fields"
}
```

---

## 📊 Player Score Update Schema

### Avro Schema

```json
{
  "type": "record",
  "name": "PlayerScoreUpdate",
  "namespace": "com.fantasy.events.scoring",
  "version": 1,
  "doc": "Player scoring update event",
  "fields": [
    {
      "name": "updateId",
      "type": "string",
      "doc": "Unique update identifier (UUID)"
    },
    {
      "name": "playerId",
      "type": "string",
      "doc": "Player identifier (UUID)"
    },
    {
      "name": "matchId",
      "type": "string",
      "doc": "Match identifier (UUID)"
    },
    {
      "name": "leagueId",
      "type": ["null", "string"],
      "default": null,
      "doc": "League identifier (UUID, nullable for global updates)"
    },
    {
      "name": "weekId",
      "type": ["null", "string"],
      "default": null,
      "doc": "Week identifier (UUID, nullable)"
    },
    {
      "name": "timestamp",
      "type": "long",
      "logicalType": "timestamp-millis",
      "doc": "Update timestamp"
    },
    {
      "name": "pointsAdded",
      "type": "double",
      "doc": "Points added in this update"
    },
    {
      "name": "totalPoints",
      "type": "double",
      "doc": "Total accumulated points"
    },
    {
      "name": "eventType",
      "type": "string",
      "doc": "Triggering event type (GOL, ASISTENCIA, etc.)"
    },
    {
      "name": "isBonus",
      "type": "boolean",
      "default": false,
      "doc": "True if this is a post-match bonus"
    },
    {
      "name": "description",
      "type": ["null", "string"],
      "default": null,
      "doc": "Human-readable description"
    },
    {
      "name": "ruleId",
      "type": ["null", "string"],
      "default": null,
      "doc": "Scoring rule that generated this update"
    }
  ]
}
```

---

## 🔄 Trade Lifecycle Event Schema

### Avro Schema

```json
{
  "type": "record",
  "name": "TradeLifecycleEvent",
  "namespace": "com.fantasy.events.trade",
  "version": 1,
  "doc": "Trade lifecycle state change event",
  "fields": [
    {
      "name": "eventId",
      "type": "string",
      "doc": "Event identifier (UUID)"
    },
    {
      "name": "tradeId",
      "type": "string",
      "doc": "Trade identifier (UUID)"
    },
    {
      "name": "leagueId",
      "type": "string",
      "doc": "League identifier (UUID)"
    },
    {
      "name": "timestamp",
      "type": "long",
      "logicalType": "timestamp-millis"
    },
    {
      "name": "eventType",
      "type": {
        "type": "enum",
        "name": "TradeEventType",
        "symbols": [
          "PROPOSED",
          "ACCEPTED",
          "REJECTED",
          "CANCELLED",
          "EXPIRED",
          "COMMISSIONER_APPROVED",
          "COMMISSIONER_REJECTED",
          "FLAGGED_FOR_REVIEW"
        ]
      }
    },
    {
      "name": "offeringTeamId",
      "type": "string",
      "doc": "Team making the offer (UUID)"
    },
    {
      "name": "receivingTeamId",
      "type": "string",
      "doc": "Team receiving the offer (UUID)"
    },
    {
      "name": "offeredPlayers",
      "type": {
        "type": "array",
        "items": "string"
      },
      "doc": "Player IDs being offered"
    },
    {
      "name": "requestedPlayers",
      "type": {
        "type": "array",
        "items": "string"
      },
      "doc": "Player IDs being requested"
    },
    {
      "name": "initiatedBy",
      "type": "string",
      "doc": "User who initiated this state change (UUID)"
    },
    {
      "name": "reason",
      "type": ["null", "string"],
      "default": null,
      "doc": "Reason for rejection/cancellation"
    },
    {
      "name": "fraudScore",
      "type": ["null", "double"],
      "default": null,
      "doc": "Fraud detection score (0.0-1.0)"
    }
  ]
}
```

---

## 🏆 League Event Schema

### Avro Schema

```json
{
  "type": "record",
  "name": "LeagueEvent",
  "namespace": "com.fantasy.events.league",
  "version": 1,
  "doc": "League configuration or state change event",
  "fields": [
    {
      "name": "eventId",
      "type": "string"
    },
    {
      "name": "leagueId",
      "type": "string"
    },
    {
      "name": "timestamp",
      "type": "long",
      "logicalType": "timestamp-millis"
    },
    {
      "name": "eventType",
      "type": {
        "type": "enum",
        "name": "LeagueEventType",
        "symbols": [
          "CREATED",
          "SETTINGS_CHANGED",
          "TEAM_JOINED",
          "TEAM_LEFT",
          "DRAFT_STARTED",
          "DRAFT_COMPLETED",
          "SEASON_STARTED",
          "SEASON_ENDED",
          "PLAYOFF_STARTED",
          "CHAMPION_DETERMINED"
        ]
      }
    },
    {
      "name": "initiatedBy",
      "type": "string",
      "doc": "User who initiated this change (UUID)"
    },
    {
      "name": "changes",
      "type": {
        "type": "map",
        "values": "string"
      },
      "default": {},
      "doc": "Changed fields with before/after values"
    },
    {
      "name": "affectedTeamId",
      "type": ["null", "string"],
      "default": null,
      "doc": "Team affected by this event (for TEAM_JOINED, TEAM_LEFT)"
    }
  ]
}
```

---

## 🔔 Notification Event Schema

### Avro Schema

```json
{
  "type": "record",
  "name": "NotificationEvent",
  "namespace": "com.fantasy.events.notification",
  "version": 1,
  "doc": "Notification delivery request",
  "fields": [
    {
      "name": "notificationId",
      "type": "string"
    },
    {
      "name": "userId",
      "type": "string",
      "doc": "Target user (UUID)"
    },
    {
      "name": "timestamp",
      "type": "long",
      "logicalType": "timestamp-millis"
    },
    {
      "name": "type",
      "type": {
        "type": "enum",
        "name": "NotificationType",
        "symbols": [
          "TRADE_PROPOSED",
          "TRADE_ACCEPTED",
          "TRADE_REJECTED",
          "WAIVER_CLAIM_PROCESSED",
          "MATCH_STARTING_SOON",
          "LIVE_SCORE_UPDATE",
          "WEEKLY_RECAP",
          "PLAYOFF_ADVANCEMENT"
        ]
      }
    },
    {
      "name": "channel",
      "type": {
        "type": "enum",
        "name": "NotificationChannel",
        "symbols": ["EMAIL", "PUSH", "IN_APP", "SMS"]
      }
    },
    {
      "name": "priority",
      "type": {
        "type": "enum",
        "name": "NotificationPriority",
        "symbols": ["LOW", "NORMAL", "HIGH", "URGENT"]
      },
      "default": "NORMAL"
    },
    {
      "name": "subject",
      "type": "string",
      "doc": "Notification subject/title"
    },
    {
      "name": "body",
      "type": "string",
      "doc": "Notification content"
    },
    {
      "name": "metadata",
      "type": {
        "type": "map",
        "values": "string"
      },
      "default": {},
      "doc": "Additional context (leagueId, tradeId, etc.)"
    },
    {
      "name": "expiresAt",
      "type": ["null", "long"],
      "logicalType": "timestamp-millis",
      "default": null,
      "doc": "Expiration timestamp for time-sensitive notifications"
    }
  ]
}
```

---

## 🔧 Schema Registry Configuration

### Confluent Schema Registry

```yaml
# docker-compose.yml excerpt
schema-registry:
  image: confluentinc/cp-schema-registry:7.5.0
  hostname: schema-registry
  ports:
    - "8081:8081"
  environment:
    SCHEMA_REGISTRY_HOST_NAME: schema-registry
    SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: 'kafka:9092'
    SCHEMA_REGISTRY_LISTENERS: http://0.0.0.0:8081
    SCHEMA_REGISTRY_SCHEMA_COMPATIBILITY_LEVEL: FULL
```

### Producer with Schema Registry

```java
@Configuration
public class AvroProducerConfig {

    @Bean
    public ProducerFactory<String, MatchEvent> avroProducerFactory() {
        Map<String, Object> config = new HashMap<>();

        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaBootstrapServers);
        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);

        // Avro serializer with Schema Registry
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG,
            KafkaAvroSerializer.class);
        config.put("schema.registry.url", schemaRegistryUrl);

        // Auto-register schemas
        config.put("auto.register.schemas", true);

        // Use specific Avro reader
        config.put("specific.avro.reader", true);

        return new DefaultKafkaProducerFactory<>(config);
    }
}
```

### Consumer with Schema Registry

```java
@Configuration
public class AvroConsumerConfig {

    @Bean
    public ConsumerFactory<String, MatchEvent> avroConsumerFactory() {
        Map<String, Object> config = new HashMap<>();

        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, kafkaBootstrapServers);
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "scoring-engine");
        config.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);

        // Avro deserializer with Schema Registry
        config.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,
            KafkaAvroDeserializer.class);
        config.put("schema.registry.url", schemaRegistryUrl);

        // Use specific Avro reader (not generic)
        config.put("specific.avro.reader", true);

        return new DefaultKafkaConsumerFactory<>(config);
    }
}
```

---

## 📊 Schema Management

### Register Schema

```bash
# Register MatchEvent schema v2
curl -X POST http://localhost:8081/subjects/match.events-value/versions \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{
    "schema": "{\"type\":\"record\",\"name\":\"MatchEvent\", ... }"
  }'

# Response:
# {"id":1}
```

### Get Latest Schema

```bash
curl http://localhost:8081/subjects/match.events-value/versions/latest

# Response:
# {
#   "subject": "match.events-value",
#   "version": 2,
#   "id": 2,
#   "schema": "{...}"
# }
```

### Check Compatibility

```bash
curl -X POST http://localhost:8081/compatibility/subjects/match.events-value/versions/latest \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d '{
    "schema": "{\"type\":\"record\",\"name\":\"MatchEvent\", ... }"
  }'

# Response:
# {"is_compatible": true}
```

### List All Schemas

```bash
curl http://localhost:8081/subjects

# Response:
# [
#   "match.events-value",
#   "scoring.player-updates-value",
#   "trade.lifecycle-value"
# ]
```

---

## 🧪 Schema Testing

### Schema Compatibility Tests

```java
@SpringBootTest
class SchemaCompatibilityTest {

    @Autowired
    private SchemaRegistryClient schemaRegistry;

    @Test
    void shouldBeBackwardCompatible() {
        var v1Schema = loadSchema("match-event-v1.avsc");
        var v2Schema = loadSchema("match-event-v2.avsc");

        // V2 can read data written with V1
        var compatibility = AvroCompatibilityChecker.checkBackward(
            v2Schema,
            Collections.singletonList(v1Schema)
        );

        assertThat(compatibility.getCompatibilityType())
            .isEqualTo(AvroCompatibilityChecker.CompatibilityType.COMPATIBLE);
    }

    @Test
    void shouldDeserializeOldData() {
        // Create event with V1 schema
        var v1Event = createV1Event();
        var serialized = serializeWithSchema(v1Event, v1Schema);

        // Deserialize with V2 schema
        var v2Event = deserializeWithSchema(serialized, v2Schema, MatchEvent.class);

        // Should work - new fields get default values
        assertThat(v2Event.getMetadata()).isEmpty();
        assertThat(v2Event.getEventId()).isEqualTo(v1Event.getEventId());
    }
}
```

---

## 📈 Schema Metrics

### Track Schema Usage

```java
@Component
public class SchemaMetrics {

    private final Counter schemaErrors;
    private final Gauge activeSchemas;

    public SchemaMetrics(MeterRegistry registry) {
        this.schemaErrors = Counter.builder("schema.errors")
            .tag("type", "serialization")
            .register(registry);

        this.activeSchemas = Gauge.builder("schema.active", this::getActiveSchemaCount)
            .register(registry);
    }

    public void recordSchemaError(String schemaName, Exception error) {
        schemaErrors.increment();
        log.error("Schema error for {}: {}", schemaName, error.getMessage());
    }

    private int getActiveSchemaCount() {
        // Query Schema Registry
        return schemaRegistry.getAllSubjects().size();
    }
}
```

---
