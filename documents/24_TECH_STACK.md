# Technology Stack - Fantasy Sports Hub

> **Stack Completo**: Backend, Data, Infra, Observability, DevOps

---

## 🏗️ Backend Stack

### Core Framework

| Component           | Technology     | Version | Rationale |
|---------------------|----------------|---------|-----------|
| **Language**        | Java           | 21 LTS  | Virtual threads, pattern matching, records, sealed classes |
| **Framework**       | Spring Boot    | 3.5.7   | Production-ready, reactive support, extensive ecosystem |
| **Reactive**        | Spring WebFlux | 3.5.7   | Non-blocking I/O, backpressure, scalability |
| **Reactive Library**| Project Reactor| 3.6.x   | Reactive Streams implementation, operators richness |
| **Build Tool**      | Gradle         | 8.x     | Kotlin DSL, incremental builds, dependency management |

**Dependencies**:

```groovy
dependencies {
    // Spring Boot
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.springframework.boot:spring-boot-starter-data-mongodb-reactive'
    implementation 'org.springframework.boot:spring-boot-starter-data-r2dbc'
    implementation 'org.springframework.boot:spring-boot-starter-data-redis-reactive'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-validation'

    // Kafka
    implementation 'org.apache.kafka:kafka-streams:4.1.1'
    implementation 'org.springframework.kafka:spring-kafka:4.0.0-RC1'
    implementation 'io.projectreactor.kafka:reactor-kafka:1.3.25'

    // R2DBC (Reactive SQL)
    implementation 'org.postgresql:r2dbc-postgresql:1.1.1.RELEASE'
    implementation 'io.r2dbc:r2dbc-pool:1.0.2.RELEASE'

    // EventStoreDB
    implementation 'com.eventstore:db-client-java:5.4.5'

    // Security
    implementation 'org.springframework.security:spring-security-oauth2-resource-server'
    implementation 'org.springframework.security:spring-security-oauth2-jose'
    implementation 'com.nimbusds:nimbus-jose-jwt:10.6'
    implementation 'org.bouncycastle:bcprov-jdk18on:1.82'  // Encryption

    // Resilience
    implementation 'io.github.resilience4j:resilience4j-spring-boot3:2.3.0'
    implementation 'io.github.resilience4j:resilience4j-reactor:2.3.0'
    implementation 'io.github.resilience4j:resilience4j-circuitbreaker:2.3.0'
    implementation 'io.github.resilience4j:resilience4j-ratelimiter:2.3.0'
    implementation 'io.github.resilience4j:resilience4j-retry:2.3.0'

    // Distributed Lock
    implementation 'org.redisson:redisson-spring-boot-starter:3.52.0'

    // Observability
    implementation 'io.micrometer:micrometer-registry-prometheus:1.16.0'
    implementation 'io.opentelemetry:opentelemetry-api:1.56.0'
    implementation 'io.opentelemetry:opentelemetry-sdk:1.56.0'
    implementation 'io.opentelemetry:opentelemetry-exporter-otlp:1.56.0'

    // Utilities
    implementation 'org.projectlombok:lombok:1.18.42'
    implementation 'org.mapstruct:mapstruct:1.6.3'
    implementation 'com.google.guava:guava:33.5.0-jre'

    // Testing
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'io.projectreactor:reactor-test:3.8.0'
    testImplementation 'org.testcontainers:testcontainers:2.0.1'
    testImplementation 'org.testcontainers:postgresql:1.21.3'
    testImplementation 'org.testcontainers:kafka:1.21.3'
    testImplementation 'org.testcontainers:mongodb:1.21.3'
    testImplementation 'com.squareup.okhttp3:mockwebserver:5.3.0'
}
```

---

## 🗄️ Data Layer

### Databases

| Database         | Version | Purpose           | Characteristics |
|------------------|---------|-------------------|-----------------|
| **PostgreSQL**   | 16.x    | Write Model (CRUD)| ACID, relational, R2DBC reactive driver |
| **EventStoreDB** | 23.x    | Event Store       | Event sourcing, append-only, projections |
| **MongoDB**      | 7.x     | Read Models (CQRS)| Denormalized, document-based, reactive driver |
| **Redis**        | 7.x     | Cache + Sessions  | In-memory, pub/sub, distributed locking |

### Message Broker

| Component           | Version | Purpose           |
|---------------------|---------|-------------------|
| **Kafka**           | 3.6.x   | Event streaming, event bus |
| **Kafka Streams**   | 3.6.x   | Stream processing |
| **Schema Registry** | 7.5.x   | Avro schema management |

**Kafka Topics**:

```yaml
topics:
  - name: raw-sports-events
    partitions: 10
    replication: 3
    retention: 7 days
    compression: snappy

  - name: normalized-match-events
    partitions: 10
    replication: 3
    retention: 30 days
    compression: snappy

  - name: scoring-events
    partitions: 10
    replication: 3
    retention: 30 days
    compression: snappy

  - name: system-events
    partitions: 5
    replication: 3
    retention: 90 days
    compression: snappy
```

---

## 🔐 Security Stack

| Component             | Technology        | Purpose           |
|-----------------------|-------------------|-------------------|
| **Authentication**    | JWT (RS256)       | Stateless auth with public/private key |
| **Token Library**     | Nimbus JOSE + JWT | JWT encoding/decoding |
| **Password Hashing**  | Argon2id          | Secure password storage |
| **Encryption**        | AES-256-GCM       | Field-level encryption (PII) |
| **TLS**               | TLS 1.3           | Transport encryption |
| **Secrets Management**| HashiCorp Vault / AWS Secrets Manager | Secret storage and rotation |

**Security Libraries**:

```groovy
dependencies {
    // Password Hashing
    implementation 'de.mkammerer:argon2-jvm:2.11'

    // Encryption
    implementation 'org.bouncycastle:bcprov-jdk18on:1.77'

    // JWT
    implementation 'com.nimbusds:nimbus-jose-jwt:9.37'
    implementation 'org.springframework.security:spring-security-oauth2-jose'
}
```

---

## 📊 Observability Stack

### Metrics

| Component           | Version | Purpose           |
|---------------------|---------|-------------------|
| **Micrometer**      | 1.12.x  | Metrics facade    |
| **Prometheus**      | 2.48.x  | Metrics storage and querying |
| **Grafana**         | 10.2.x  | Metrics visualization |

**Metrics Exposed**:
- Application: Request rate, latency, errors
- JVM: Heap, GC, threads, CPU
- Business: Active users, scores calculated, events processed
- Infrastructure: Database connections, Kafka lag, cache hit rate

### Distributed Tracing

| Component         | Version | Purpose           |
|-------------------|---------|-------------------|
| **OpenTelemetry** | 1.32.x  | Tracing instrumentation |
| **Jaeger**        | 1.51.x  | Trace storage and visualization |

### Logging

| Component              | Version | Purpose           |
|------------------------|---------|-------------------|
| **Logback**            | 1.4.x   | Logging framework |
| **SLF4J**              | 2.0.x   | Logging facade |
| **Structured Logging** | Logstash JSON Encoder | JSON-formatted logs |

**Log Format**:

```json
{
  "timestamp": "2025-11-08T10:23:45.123Z",
  "level": "INFO",
  "logger": "com.fantasy.ScoringEngine",
  "thread": "reactor-http-nio-3",
  "message": "Score calculated",
  "matchId": "match-123",
  "playerId": "player-456",
  "points": 10,
  "traceId": "abc123def456",
  "spanId": "789ghi"
}
```

---

## 🚀 Infrastructure & Deployment

### Container Orchestration

| Component        | Version | Purpose           |
|------------------|---------|-------------------|
| **Kubernetes**   | 1.28.x  | Container orchestration |
| **Helm**         | 3.13.x  | Package management |
| **Strimzi**      | 0.38.x  | Kafka operator for K8s |
| **Cert-Manager** | 1.13.x  | TLS certificate management |

### Container Runtime

| Component    | Version | Purpose           |
|--------------|---------|-------------------|
| **Docker**   | 24.x    | Container runtime |
| **BuildKit** | Latest  | Image building    |

**Dockerfile Example**:
```dockerfile
FROM eclipse-temurin:21-jre-alpine

# Security: non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Application
WORKDIR /app
COPY --chown=spring:spring build/libs/fantasy-sports-api.jar app.jar

# JVM Tuning
ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -Xms4g -Xmx4g"

EXPOSE 8080 8081

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### Cloud Infrastructure

| Provider              | Services Used | Purpose           |
|-----------------------|---------------|-------------------|
| **AWS** (Recommended) | EKS, RDS, ElastiCache, MSK | Managed Kubernetes, databases, Kafka |
| **GCP** (Alternative) | GKE, Cloud SQL, Memorystore, Pub/Sub | Similar managed services |
| **Azure** (Alternative)| AKS, Azure Database, Azure Cache | Similar managed services |

---

## 🔄 CI/CD Stack

### CI/CD Platform

| Component                  | Purpose           |
|----------------------------|-------------------|
| **GitHub Actions**         | CI/CD orchestration |
| **SonarQube**              | Code quality & security scanning |
| **Snyk**                   | Dependency vulnerability scanning |
| **OWASP Dependency-Check** | Security vulnerability detection |

**Pipeline Stages**:
```yaml
stages:
  - lint: Code quality checks
  - test: Unit + integration tests
  - security: SAST, dependency checks
  - build: Docker image build
  - scan: Container vulnerability scan
  - deploy-staging: Deploy to staging
  - smoke-test: Automated smoke tests
  - deploy-canary: 10% traffic to new version
  - monitor: Validate metrics for 5 min
  - deploy-production: Blue-green deployment
```

### Code Quality Tools

| Tool           | Purpose                | Integration     |
|----------------|------------------------|-----------------|
| **Checkstyle** | Code style enforcement | Pre-commit hook |
| **SpotBugs**   | Static analysis        | CI pipeline     |
| **PMD**        | Code quality           | CI pipeline     |
| **JaCoCo**     | Code coverage          | Require 80% coverage |

---

## 🧪 Testing Stack

### Testing Frameworks

| Framework          | Version | Purpose           |
|--------------------|---------|-------------------|
| **JUnit 5**        | 5.10.x  | Unit testing      |
| **Mockito**        | 5.7.x   | Mocking           |
| **AssertJ**        | 3.24.x  | Fluent assertions |
| **Reactor Test**   | 3.6.x   | Reactive testing (StepVerifier) |
| **TestContainers** | 1.19.x | Integration testing with real containers |
| **Pact**           | 4.6.x   | Contract testing |
| **WireMock**       | 3.3.x   | HTTP mocking |

**Test Configuration**:

```groovy
test {
    useJUnitPlatform()

    testLogging {
        events "passed", "skipped", "failed"
        showStandardStreams = true
    }

    // Parallel execution
    maxParallelForks = Runtime.runtime.availableProcessors().intdiv(2) ?: 1

    // JaCoCo coverage
    finalizedBy jacocoTestReport
}

jacocoTestReport {
    reports {
        xml.required = true
        html.required = true
    }
}

jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = 0.80  // 80% coverage required
            }
        }
    }
}
```

---

## 📦 External APIs

### Sports Data Providers

| Provider           | Sports          | Pricing | Usage           |
|--------------------|-----------------|---------|-----------------|
| **API-Football**   | Football/Soccer | Freemium | Primary for football |
| **SportsData.io**  | Multiple (NBA, MLB, NHL) | Paid | Multi-sport fallback |
| **MLB Stats API**  | Baseball        | Free    | Primary for baseball |
| **NHL API**        | Hockey          | Free    | Primary for hockey |

### Third-Party Services

| Service                | Purpose                | Provider |
|------------------------|------------------------|----------|
| **Email**              | Transactional emails   | SendGrid / AWS SES |
| **Push Notifications** | Mobile push            | Firebase Cloud Messaging |
| **SMS**                | 2FA, alerts            | Twilio   |
| **Analytics**          | User behavior          | Mixpanel / Amplitude |

---

## 📋 Development Tools

### IDE & Editors

| Tool              | Purpose                |
|-------------------|------------------------|
| **IntelliJ IDEA** | Primary Java IDE       |
| **VS Code**       | Lightweight editing, YAML/JSON |

### Version Control

| Tool       | Purpose                |
|------------|------------------------|
| **Git**    | Version control        |
| **GitHub** | Code hosting, CI/CD, issues |

### API Development

| Tool           | Purpose                |
|----------------|------------------------|
| **Postman**    | API testing            |
| **Insomnia**   | Alternative API client |
| **Swagger UI** | OpenAPI documentation |

### Database Tools

| Tool                | Purpose                |
|---------------------|------------------------|
| **DBeaver**         | Database client (PostgreSQL, MongoDB) |
| **Redis Commander** | Redis GUI |
| **MongoDB Compass** | MongoDB GUI |

---

## 🔧 Local Development Stack

### Docker Compose

```yaml
# docker-compose.yml
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: fantasy_sports
      POSTGRES_USER: fantasy
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
    ports:
      - "9092:9092"
    depends_on:
      - zookeeper

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    ports:
      - "2181:2181"

  eventstore:
    image: eventstore/eventstore:23.10.0-alpha-arm64v8
    environment:
      EVENTSTORE_INSECURE: true
      EVENTSTORE_ENABLE_ATOM_PUB_OVER_HTTP: true
    ports:
      - "1113:1113"
      - "2113:2113"

volumes:
  postgres_data:
  mongo_data:
```

### Environment Setup

```bash
# Install Java 21
sdk install java 21.0.1-tem
sdk use java 21.0.1-tem

# Install Gradle
sdk install gradle 8.5

# Start local infrastructure
docker-compose up -d

# Run application
./gradlew bootRun

# Run tests
./gradlew test integrationTest

# Build Docker image
./gradlew bootBuildImage
```

---

## 📊 Performance Characteristics

### Target Metrics

| Metric                  | Target    | Measurement                |
|-------------------------|-----------|----------------------------|
| **API Latency (P95)**   | < 200ms   | Prometheus histogram       |
| **WebSocket Latency**   | < 500ms   | Custom metric              |
| **Throughput**          | 10K req/s | Prometheus counter         |
| **Concurrent Users**    | 100K+     | WebSocket connections gauge |
| **Database Connections** | < 100 per pod | HikariCP metrics |
| **Kafka Lag**           | < 1000 messages | Kafka consumer lag |
| **JVM Heap Usage**      | < 80% | JVM metrics |

### JVM Tuning

```bash
# Production JVM Flags
JAVA_OPTS="
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=200
  -XX:+UseStringDeduplication
  -XX:+ParallelRefProcEnabled
  -XX:InitiatingHeapOccupancyPercent=45
  -Xms4g
  -Xmx4g
  -XX:MaxDirectMemorySize=1g
  -XX:+HeapDumpOnOutOfMemoryError
  -XX:HeapDumpPath=/logs/heapdump.hprof
  -XX:+ExitOnOutOfMemoryError
"
```

---

## 🔒 Security Compliance

### Standards

| Standard          | Compliance Level |
|-------------------|------------------|
| **OWASP Top 10**  | Full compliance  |
| **GDPR**          | Full compliance (EU) |
| **CCPA**          | Full compliance (California) |
| **SOC 2 Type II** | Target for enterprise |

### Security Scanning

| Tool          | Frequency     | Purpose                |
|---------------|---------------|------------------------|
| **Snyk**      | Every commit  | Dependency vulnerabilities |
| **SonarQube** | Every PR      | Code security issues |
| **OWASP ZAP** | Weekly        | Dynamic security testing |
| **Trivy**     | Every image build | Container vulnerabilities |

---

## 📚 Documentation Stack

| Tool            | Purpose                |
|-----------------|------------------------|
| **Markdown**    | Documentation format   |
| **Mermaid**     | Diagrams as code       |
| **OpenAPI 3.0** | REST API specification |
| **AsyncAPI**    | WebSocket protocol specification |
| **Confluence**  | Team wiki (optional) |

---

## 🌍 Production Architecture

### Deployment Topology

```
Region: us-east-1 (Primary)
├─ AZ-1
│  ├─ API Pods (3-15)
│  ├─ Kafka Broker 1
│  ├─ PostgreSQL Primary
│  └─ MongoDB Primary
├─ AZ-2
│  ├─ API Pods (3-15)
│  ├─ Kafka Broker 2
│  ├─ PostgreSQL Replica 1
│  └─ MongoDB Secondary
└─ AZ-3
   ├─ API Pods (4-20)
   ├─ Kafka Broker 3
   ├─ PostgreSQL Replica 2
   └─ MongoDB Secondary

Region: us-west-2 (DR - Disaster Recovery)
└─ Full replica (warm standby)
```

---

## 📈 Scalability Targets

| Component         | Min                   | Typical | Peak |
|-------------------|-----------------------|---------|------|
| **API Pods**      | 10                    | 20      | 50   |
| **Kafka Brokers** | 3                     | 5       | 7    |
| **PostgreSQL**    | 1 primary + 2 replicas | Same | + 1 replica |
| **MongoDB**       | 1 primary + 2 secondary | Same | + 1 secondary |
| **Redis**         | 1 master + 1 replica | Same | Cluster (6 nodes) |

---

## 💰 Estimated Costs (AWS)

### Monthly Cost Projection (Year 1)

| Component                | Configuration | Monthly Cost |
|--------------------------|---------------|--------------|
| **EKS Cluster**          | Control plane + nodes | $500 |
| **EC2 (K8s nodes)**      | 20x r6i.2xlarge (64GB RAM) | $4,000 |
| **RDS PostgreSQL**       | db.r6g.2xlarge + replicas | $1,500 |
| **DocumentDB (MongoDB)** | db.r6g.xlarge + replicas | $1,200 |
| **ElastiCache (Redis)**  | cache.r6g.large cluster | $400 |
| **MSK (Kafka)**          | kafka.m5.xlarge x3 | $1,200 |
| **S3 (backups, logs)**   | 500 GB | $15 |
| **CloudWatch**           | Logs + metrics | $200 |
| **Data Transfer**        | 5 TB/month | $450 |
| **Sports APIs**          | API-Football + SportsData | $500 |

**Total Monthly**: ~$9,965
**Total Annual**: ~$120,000

*Note: Costs scale with usage. Peak season may be 2x.*

---

## 🔮 Technology Roadmap

### Near Term (Next 6 months)
- [ ] Upgrade to Java 22 (when LTS)
- [ ] Implement WebFlux coroutines support
- [ ] Add GraphQL endpoint option
- [ ] Enhance ML fraud detection models

### Medium Term (6-12 months)
- [ ] Migrate to GraalVM native images
- [ ] Add real-time analytics with ClickHouse
- [ ] Implement CDC (Change Data Capture) with Debezium
- [ ] Multi-region active-active setup

### Long Term (12+ months)
- [ ] Explore edge computing for scoring
- [ ] AI-powered player projections
- [ ] Blockchain for transaction immutability
- [ ] AR/VR integration for match viewing

---
