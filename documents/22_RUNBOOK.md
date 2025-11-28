# Runbook - Operations Manual

> **Operations Playbook**: Procedures for operation, troubleshooting, and disaster recovery

---

## 🎯 Overview

This runbook contains operational procedures for the SRE/DevOps team that maintains the Fantasy Sports Hub system in production.

**Audience**: SRE, DevOps, On-Call Engineers
**Criticality**: 24/7 Production
**SLA Target**: 99.9% uptime

---

## 🚀 Startup Procedures

### Complete System Startup

**Startup sequence** (order is important):

```bash
#!/bin/bash
# startup-sequence.sh

# 1. Infrastructure layer
echo "Starting infrastructure services..."
kubectl apply -f k8s/infrastructure/

# Wait for infrastructure
kubectl wait --for=condition=ready pod -l tier=infrastructure -n fantasy-sports --timeout=300s

# 2. Data layer
echo "Starting data services..."
kubectl apply -f k8s/databases/

# Wait for databases
kubectl wait --for=condition=ready pod -l tier=data -n fantasy-sports --timeout=600s

# 3. Message layer
echo "Starting Kafka..."
kubectl apply -f k8s/kafka/

kubectl wait --for=condition=ready pod -l app=kafka -n fantasy-sports --timeout=300s

# 4. Application layer
echo "Starting application services..."
kubectl apply -f k8s/applications/

# Wait for applications
kubectl wait --for=condition=ready pod -l tier=application -n fantasy-sports --timeout=300s

# 5. Verify health
echo "Checking system health..."
./scripts/health-check.sh

echo "Startup complete!"
```

### Individual Service Startup

```bash
# Start API service
kubectl scale deployment fantasy-api --replicas=10 -n fantasy-sports

# Start WebSocket service
kubectl scale deployment fantasy-websocket --replicas=5 -n fantasy-sports

# Start workers
kubectl scale deployment fantasy-worker --replicas=3 -n fantasy-sports
```

---

## 🛑 Shutdown Procedures

### Graceful Shutdown

```bash
#!/bin/bash
# shutdown-sequence.sh

# 1. Stop accepting new traffic
echo "Draining traffic..."
kubectl patch service fantasy-api -p '{"spec":{"type":"ClusterIP"}}' -n fantasy-sports

# Wait for active connections to drain (5 minutes)
sleep 300

# 2. Scale down applications
echo "Scaling down applications..."
kubectl scale deployment fantasy-api --replicas=0 -n fantasy-sports
kubectl scale deployment fantasy-websocket --replicas=0 -n fantasy-sports
kubectl scale deployment fantasy-worker --replicas=0 -n fantasy-sports

# Wait for pods to terminate
kubectl wait --for=delete pod -l tier=application -n fantasy-sports --timeout=120s

# 3. Stop message layer
echo "Stopping Kafka..."
kubectl scale statefulset kafka --replicas=0 -n fantasy-sports

# 4. Stop databases (ONLY if full shutdown needed)
read -p "Stop databases? (y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Stopping databases..."
    kubectl scale statefulset postgres --replicas=0 -n fantasy-sports
    kubectl scale statefulset mongodb --replicas=0 -n fantasy-sports
    kubectl scale statefulset redis --replicas=0 -n fantasy-sports
fi

echo "Shutdown complete!"
```

### Emergency Shutdown

```bash
# EMERGENCY: Immediate shutdown (no graceful drain)
kubectl delete deployment --all -n fantasy-sports
kubectl delete statefulset --all -n fantasy-sports
```

---

## 🔍 Health Checks

### System Health Check Script

```bash
#!/bin/bash
# health-check.sh

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_service() {
    local service=$1
    local endpoint=$2

    if curl -sf "$endpoint" > /dev/null; then
        echo -e "${GREEN}✓${NC} $service is healthy"
        return 0
    else
        echo -e "${RED}✗${NC} $service is DOWN"
        return 1
    fi
}

echo "Checking system health..."

# API
check_service "API" "http://fantasy-api/actuator/health"

# WebSocket
check_service "WebSocket" "http://fantasy-websocket/actuator/health"

# PostgreSQL
kubectl exec -it postgres-0 -n fantasy-sports -- pg_isready
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} PostgreSQL is healthy"
else
    echo -e "${RED}✗${NC} PostgreSQL is DOWN"
fi

# MongoDB
kubectl exec -it mongodb-0 -n fantasy-sports -- mongosh --eval "db.adminCommand('ping')"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} MongoDB is healthy"
else
    echo -e "${RED}✗${NC} MongoDB is DOWN"
fi

# Redis
kubectl exec -it redis-0 -n fantasy-sports -- redis-cli ping
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Redis is healthy"
else
    echo -e "${RED}✗${NC} Redis is DOWN"
fi

# Kafka
kubectl exec -it kafka-0 -n fantasy-sports -- kafka-broker-api-versions --bootstrap-server localhost:9092
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Kafka is healthy"
else
    echo -e "${RED}✗${NC} Kafka is DOWN"
fi
```

---

## 🚨 Common Issues & Troubleshooting

### Issue: API Pods Crashing (CrashLoopBackOff)

**Symptoms**:
- Pods in CrashLoopBackOff state
- High restart count
- 503 errors from load balancer

**Diagnosis**:
```bash
# Check pod status
kubectl get pods -n fantasy-sports | grep api

# Check pod logs
kubectl logs -n fantasy-sports fantasy-api-xxx --previous

# Check events
kubectl describe pod fantasy-api-xxx -n fantasy-sports
```

**Common Causes & Solutions**:

1. **Database connection failure**
   ```bash
   # Check DB connectivity
   kubectl exec -it fantasy-api-xxx -n fantasy-sports -- nc -zv postgres 5432

   # Solution: Verify DB credentials in secrets
   kubectl get secret fantasy-secrets -n fantasy-sports -o yaml
   ```

2. **Out of Memory (OOM)**
   ```bash
   # Check memory usage
   kubectl top pods -n fantasy-sports

   # Solution: Increase memory limits
   kubectl patch deployment fantasy-api -n fantasy-sports -p '{"spec":{"template":{"spec":{"containers":[{"name":"fantasy-api","resources":{"limits":{"memory":"4Gi"}}}]}}}}'
   ```

3. **Failed health checks**
   ```bash
   # Test health endpoint manually
   kubectl port-forward fantasy-api-xxx 8081:8081 -n fantasy-sports
   curl http://localhost:8081/actuator/health

   # Solution: Increase readiness probe initial delay
   kubectl patch deployment fantasy-api -n fantasy-sports --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/initialDelaySeconds","value":60}]'
   ```

---

### Issue: High Latency / Slow Responses

**Symptoms**:
- P95 latency > 1000ms
- Users reporting slow page loads
- Timeout errors

**Diagnosis**:
```bash
# Check API latency metrics
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Open browser: http://localhost:9090
# Query: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m]))

# Check database query times
kubectl exec -it postgres-0 -n fantasy-sports -- psql -U fantasy_user -d fantasy_sports -c "SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"

# Check Redis hit rate
kubectl exec -it redis-0 -n fantasy-sports -- redis-cli INFO stats | grep keyspace
```

**Solutions**:

1. **Database slow queries**
   ```sql
   -- Add missing index
   CREATE INDEX CONCURRENTLY idx_roster_user_week ON roster_entries(user_id, week_id);
   ```

2. **Cache misses**
   ```bash
   # Warm up cache
   kubectl exec -it fantasy-api-xxx -n fantasy-sports -- curl -X POST http://localhost:8081/actuator/caches/warm-up
   ```

3. **Scale up**
   ```bash
   # Increase replicas
   kubectl scale deployment fantasy-api --replicas=20 -n fantasy-sports
   ```

---

### Issue: Kafka Consumer Lag

**Symptoms**:
- Events not processed in real-time
- Growing consumer lag
- Delayed score updates

**Diagnosis**:
```bash
# Check consumer lag
kubectl exec -it kafka-0 -n fantasy-sports -- kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group scoring-engine

# Output:
# GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
# scoring-engine  match-events    0          1000            5000            4000  ← Problem!
```

**Solutions**:

1. **Increase consumer parallelism**
   ```bash
   # Scale up worker pods
   kubectl scale deployment fantasy-worker --replicas=10 -n fantasy-sports
   ```

2. **Increase Kafka partitions**
   ```bash
   kubectl exec -it kafka-0 -n fantasy-sports -- kafka-topics --bootstrap-server localhost:9092 --alter --topic match-events --partitions 24
   ```

3. **Reset consumer offset (if safe)**
   ```bash
   # CAUTION: This skips unprocessed messages
   kubectl exec -it kafka-0 -n fantasy-sports -- kafka-consumer-groups --bootstrap-server localhost:9092 --group scoring-engine --reset-offsets --to-latest --execute --topic match-events
   ```

---

### Issue: Database Disk Full

**Symptoms**:
- Write operations failing
- Pods showing disk pressure
- Alerts for PV usage > 90%

**Diagnosis**:
```bash
# Check PV usage
kubectl exec -it postgres-0 -n fantasy-sports -- df -h

# Check database size
kubectl exec -it postgres-0 -n fantasy-sports -- psql -U fantasy_user -c "SELECT pg_size_pretty(pg_database_size('fantasy_sports'));"
```

**Solutions**:

1. **Clean up old data**
   ```sql
   -- Delete old audit logs
   DELETE FROM audit_logs WHERE timestamp < NOW() - INTERVAL '6 months';

   -- Vacuum to reclaim space
   VACUUM FULL audit_logs;
   ```

2. **Expand PV**
   ```bash
   # Edit PVC to request more storage
   kubectl edit pvc postgres-storage-postgres-0 -n fantasy-sports
   # Change: storage: 500Gi → storage: 1Ti
   ```

3. **Archive to S3**
   ```bash
   # Backup and archive old data
   kubectl exec -it postgres-0 -n fantasy-sports -- pg_dump -U fantasy_user -t audit_logs --data-only | gzip > audit_logs_$(date +%Y%m%d).sql.gz
   aws s3 cp audit_logs_$(date +%Y%m%d).sql.gz s3://fantasy-backups/archives/
   ```

---

## 💾 Backup & Restore

### Database Backup

```bash
#!/bin/bash
# backup-databases.sh

BACKUP_DIR="/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# PostgreSQL backup
echo "Backing up PostgreSQL..."
kubectl exec -it postgres-0 -n fantasy-sports -- pg_dump -U fantasy_user fantasy_sports | gzip > $BACKUP_DIR/postgres_$(date +%Y%m%d_%H%M%S).sql.gz

# MongoDB backup
echo "Backing up MongoDB..."
kubectl exec -it mongodb-0 -n fantasy-sports -- mongodump --archive | gzip > $BACKUP_DIR/mongodb_$(date +%Y%m%d_%H%M%S).archive.gz

# EventStoreDB backup
echo "Backing up EventStoreDB..."
kubectl exec -it eventstore-0 -n fantasy-sports -- tar -czf - /var/lib/eventstore > $BACKUP_DIR/eventstore_$(date +%Y%m%d_%H%M%S).tar.gz

# Upload to S3
echo "Uploading to S3..."
aws s3 sync $BACKUP_DIR s3://fantasy-backups/daily/$(date +%Y%m%d)/

echo "Backup complete!"
```

### Database Restore

```bash
#!/bin/bash
# restore-databases.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

# PostgreSQL restore
if [[ $BACKUP_FILE == *"postgres"* ]]; then
    echo "Restoring PostgreSQL from $BACKUP_FILE..."
    gunzip -c $BACKUP_FILE | kubectl exec -i postgres-0 -n fantasy-sports -- psql -U fantasy_user fantasy_sports
fi

# MongoDB restore
if [[ $BACKUP_FILE == *"mongodb"* ]]; then
    echo "Restoring MongoDB from $BACKUP_FILE..."
    gunzip -c $BACKUP_FILE | kubectl exec -i mongodb-0 -n fantasy-sports -- mongorestore --archive
fi

echo "Restore complete!"
```

---

## 🔧 Maintenance Tasks

### Rolling Update Deployment

```bash
# Update API to new version
kubectl set image deployment/fantasy-api fantasy-api=ghcr.io/fantasy-sports/api:1.1.0 -n fantasy-sports

# Monitor rollout
kubectl rollout status deployment/fantasy-api -n fantasy-sports

# Rollback if needed
kubectl rollout undo deployment/fantasy-api -n fantasy-sports
```

### Database Migration

```bash
# Run Flyway migration
kubectl exec -it fantasy-api-xxx -n fantasy-sports -- java -jar /app/flyway.jar migrate

# Verify migration
kubectl exec -it postgres-0 -n fantasy-sports -- psql -U fantasy_user -c "SELECT * FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5;"
```

### Clear Redis Cache

```bash
# Clear all caches
kubectl exec -it redis-0 -n fantasy-sports -- redis-cli FLUSHALL

# Clear specific pattern
kubectl exec -it redis-0 -n fantasy-sports -- redis-cli --scan --pattern "match:*" | xargs kubectl exec -it redis-0 -n fantasy-sports -- redis-cli DEL
```

---

## 🔥 Disaster Recovery

### Complete System Failure

**Recovery Steps**:

1. **Assess damage**
   ```bash
   kubectl get all -n fantasy-sports
   kubectl get pv,pvc -n fantasy-sports
   ```

2. **Restore from backup**
   ```bash
   # Restore databases from latest S3 backup
   ./scripts/restore-databases.sh s3://fantasy-backups/daily/latest/
   ```

3. **Rebuild infrastructure**
   ```bash
   # Apply all K8s manifests
   kubectl apply -f k8s/ -R
   ```

4. **Verify system health**
   ```bash
   ./scripts/health-check.sh
   ```

5. **Resume traffic**
   ```bash
   kubectl patch service fantasy-api -p '{"spec":{"type":"LoadBalancer"}}' -n fantasy-sports
   ```

---

## 📞 On-Call Procedures

### Incident Response Checklist

1. ☐ Acknowledge alert in PagerDuty
2. ☐ Check #incidents Slack channel
3. ☐ Run health check script
4. ☐ Identify affected component
5. ☐ Check runbook for solution
6. ☐ Apply fix
7. ☐ Verify resolution
8. ☐ Document incident
9. ☐ Create post-mortem (for P1/P2)

### Escalation Path

- **L1**: On-call engineer (responds within 15min)
- **L2**: Senior SRE (escalate after 30min)
- **L3**: Engineering lead (critical incidents only)

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-08
**Status**: Final
