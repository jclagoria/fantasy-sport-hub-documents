#!/bin/bash
# EventStoreDB Backup Script
# Creates compressed backup of EventStoreDB data with rotation

set -e

# Configuration
BACKUP_BASE_DIR="${EVENTSTOREDB_BACKUP_PATH:-./backups/eventstoredb}"
DATA_DIR="${EVENTSTOREDB_DATA_PATH:-./data/eventstoredb}"
RETENTION_DAYS="${EVENTSTOREDB_BACKUP_RETENTION_DAYS:-90}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/${TIMESTAMP}"

echo "🔄 Starting EventStoreDB backup..."
echo "📅 Timestamp: ${TIMESTAMP}"
echo "📂 Backup directory: ${BACKUP_DIR}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Stop container for consistent backup
echo "⏸️  Stopping EventStoreDB container..."
docker-compose -f docker-compose.eventstoredb.yml stop eventstoredb

# Backup data directory
echo "📦 Creating backup archive..."
tar -czf "${BACKUP_DIR}/eventstore-data.tar.gz" -C "${DATA_DIR}" .

# Backup configuration
echo "📝 Backing up configuration..."
cp .env.eventstoredb "${BACKUP_DIR}/"
cp docker-compose.eventstoredb.yml "${BACKUP_DIR}/"

# Get backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
echo "💾 Backup size: ${BACKUP_SIZE}"

# Restart container
echo "▶️  Starting EventStoreDB container..."
docker-compose -f docker-compose.eventstoredb.yml start eventstoredb

# Wait for health check
echo "⏳ Waiting for EventStoreDB to be healthy..."
until docker-compose -f docker-compose.eventstoredb.yml ps | grep -q "healthy"; do
  sleep 2
done

# Clean up old backups
echo "🗑️  Cleaning up old backups (retention: ${RETENTION_DAYS} days)..."
find "${BACKUP_BASE_DIR}" -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} \; 2>/dev/null || true

# Create backup metadata
cat > "${BACKUP_DIR}/metadata.json" << EOF
{
  "timestamp": "${TIMESTAMP}",
  "date": "$(date -Iseconds)",
  "size": "${BACKUP_SIZE}",
  "data_dir": "${DATA_DIR}",
  "retention_days": ${RETENTION_DAYS}
}
EOF

echo "✅ Backup completed successfully!"
echo "📍 Backup location: ${BACKUP_DIR}"
echo ""
echo "To restore from this backup:"
echo "  ./scripts/eventstoredb/restore.sh ${TIMESTAMP}"
