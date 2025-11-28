#!/bin/bash
# EventStoreDB Restore Script
# Restores EventStoreDB data from backup

set -e

# Check arguments
if [ -z "$1" ]; then
  echo "❌ Error: Backup timestamp required"
  echo ""
  echo "Usage: $0 <timestamp>"
  echo ""
  echo "Available backups:"
  ls -1 "${EVENTSTOREDB_BACKUP_PATH:-./backups/eventstoredb}" 2>/dev/null || echo "  No backups found"
  exit 1
fi

# Configuration
TIMESTAMP=$1
BACKUP_BASE_DIR="${EVENTSTOREDB_BACKUP_PATH:-./backups/eventstoredb}"
DATA_DIR="${EVENTSTOREDB_DATA_PATH:-./data/eventstoredb}"
BACKUP_DIR="${BACKUP_BASE_DIR}/${TIMESTAMP}"
BACKUP_FILE="${BACKUP_DIR}/eventstore-data.tar.gz"

echo "🔄 Starting EventStoreDB restore..."
echo "📅 Backup timestamp: ${TIMESTAMP}"
echo "📂 Backup directory: ${BACKUP_DIR}"

# Validate backup exists
if [ ! -f "${BACKUP_FILE}" ]; then
  echo "❌ Error: Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

# Display backup metadata
if [ -f "${BACKUP_DIR}/metadata.json" ]; then
  echo ""
  echo "📋 Backup metadata:"
  cat "${BACKUP_DIR}/metadata.json"
  echo ""
fi

# Confirmation prompt
read -p "⚠️  WARNING: This will replace all current data. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "❌ Restore cancelled"
  exit 0
fi

# Create backup of current data (safety measure)
SAFETY_BACKUP_DIR="${BACKUP_BASE_DIR}/pre-restore-$(date +%Y%m%d_%H%M%S)"
echo "🛡️  Creating safety backup of current data..."
mkdir -p "${SAFETY_BACKUP_DIR}"
tar -czf "${SAFETY_BACKUP_DIR}/eventstore-data.tar.gz" -C "${DATA_DIR}" . 2>/dev/null || true
echo "✅ Safety backup created: ${SAFETY_BACKUP_DIR}"

# Stop container
echo "⏸️  Stopping EventStoreDB container..."
docker-compose -f docker-compose.eventstoredb.yml stop eventstoredb

# Clear current data
echo "🗑️  Clearing current data directory..."
rm -rf "${DATA_DIR}"/*

# Restore from backup
echo "📦 Restoring data from backup..."
tar -xzf "${BACKUP_FILE}" -C "${DATA_DIR}"

# Restore configuration if available
if [ -f "${BACKUP_DIR}/.env.eventstoredb" ]; then
  echo "📝 Restoring configuration..."
  cp "${BACKUP_DIR}/.env.eventstoredb" .env.eventstoredb.restored
  echo "   Configuration saved to: .env.eventstoredb.restored"
  echo "   Review and apply manually if needed"
fi

# Fix permissions
echo "🔧 Setting permissions..."
chmod -R 755 "${DATA_DIR}"

# Start container
echo "▶️  Starting EventStoreDB container..."
docker-compose -f docker-compose.eventstoredb.yml start eventstoredb

# Wait for health check
echo "⏳ Waiting for EventStoreDB to be healthy..."
RETRY_COUNT=0
MAX_RETRIES=30

until docker-compose -f docker-compose.eventstoredb.yml ps | grep -q "healthy"; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "❌ Error: EventStoreDB failed to start after restore"
    echo ""
    echo "Safety backup is available at: ${SAFETY_BACKUP_DIR}"
    echo "To rollback, run: $0 $(basename ${SAFETY_BACKUP_DIR})"
    exit 1
  fi
  sleep 2
done

echo "✅ Restore completed successfully!"
echo ""
echo "📊 Verify restore:"
echo "  - Access Admin UI: http://localhost:2113"
echo "  - Check streams: curl -u admin:changeit http://localhost:2113/streams/\$all"
echo "  - Check projections: curl -u admin:changeit http://localhost:2113/projections/any"
echo ""
echo "🛡️  Safety backup retained at: ${SAFETY_BACKUP_DIR}"
