#!/bin/bash
# EventStoreDB Stream Initialization Script
# Creates stream categories and sets up initial projections

set -e

# Configuration
EVENTSTORE_HOST="${EVENTSTOREDB_HOST:-localhost}"
EVENTSTORE_PORT="${EVENTSTOREDB_HTTP_PORT:-2113}"
EVENTSTORE_USER="${EVENTSTOREDB_ADMIN_USER:-admin}"
EVENTSTORE_PASSWORD="${EVENTSTOREDB_ADMIN_PASSWORD:-changeit}"
BASE_URL="http://${EVENTSTORE_HOST}:${EVENTSTORE_PORT}"

echo "🔄 Initializing EventStoreDB streams and projections..."
echo "📡 EventStoreDB URL: ${BASE_URL}"

# Wait for EventStoreDB to be ready
echo "⏳ Waiting for EventStoreDB to be ready..."
until curl -s -f "${BASE_URL}/health/live" > /dev/null 2>&1; do
  echo "   Waiting for EventStoreDB..."
  sleep 2
done
echo "✅ EventStoreDB is ready!"

# Function to create continuous projection
create_projection() {
  local name=$1
  local file=$2

  echo "📝 Creating projection: ${name}"

  if [ ! -f "${file}" ]; then
    echo "❌ Projection file not found: ${file}"
    return 1
  fi

  projection_content=$(cat "${file}")

  curl -i -X POST "${BASE_URL}/projections/continuous?name=${name}&emit=yes&checkpoints=yes&enabled=yes" \
    -u "${EVENTSTORE_USER}:${EVENTSTORE_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d "${projection_content}" \
    2>/dev/null || echo "⚠️  Projection ${name} may already exist"

  echo "✅ Projection ${name} created/updated"
}

# Function to initialize stream metadata
init_stream_metadata() {
  local stream_name=$1
  local max_age=$2
  local max_count=$3

  echo "📋 Setting metadata for stream: ${stream_name}"

  metadata="{\"maxAge\": ${max_age}, \"maxCount\": ${max_count}}"

  curl -i -X POST "${BASE_URL}/streams/${stream_name}/metadata" \
    -u "${EVENTSTORE_USER}:${EVENTSTORE_PASSWORD}" \
    -H "Content-Type: application/json" \
    -H "ES-EventType: \$metadata" \
    -d "${metadata}" \
    2>/dev/null || echo "⚠️  Stream ${stream_name} metadata may already exist"

  echo "✅ Metadata set for ${stream_name}"
}

# Create projections directory path
PROJECTIONS_DIR="$(dirname "$0")/projections"

# Create projections
echo ""
echo "🔧 Creating continuous projections..."
create_projection "match-scoring" "${PROJECTIONS_DIR}/match-scoring-projection.js"
create_projection "player-statistics" "${PROJECTIONS_DIR}/player-statistics-projection.js"
create_projection "security-audit" "${PROJECTIONS_DIR}/security-audit-projection.js"

# Initialize stream metadata for different stream types
echo ""
echo "🔧 Initializing stream metadata..."

# Match streams - retain for 5 years (as per capacity planning)
init_stream_metadata '$ce-match' 157680000 999999999  # 5 years in seconds

# Player streams - retain for 5 years
init_stream_metadata '$ce-player' 157680000 999999999

# Team streams - retain for 5 years
init_stream_metadata '$ce-team' 157680000 999999999

# League streams - retain for 5 years
init_stream_metadata '$ce-league' 157680000 999999999

# Security audit - retain for 2 years
init_stream_metadata 'security-audit' 63072000 999999999  # 2 years in seconds

# Fraud detection - retain for 2 years
init_stream_metadata 'fraud-detection' 63072000 999999999

echo ""
echo "✅ EventStoreDB initialization complete!"
echo ""
echo "📊 Stream categories configured:"
echo "   - match-{matchId}     → Match events"
echo "   - player-{playerId}   → Player events"
echo "   - team-{teamId}       → Team events"
echo "   - league-{leagueId}   → League events"
echo "   - security-audit      → Security events"
echo "   - fraud-detection     → Fraud events"
echo ""
echo "🔍 Access EventStoreDB Admin UI: ${BASE_URL}"
echo "   Username: ${EVENTSTORE_USER}"
echo "   Password: ${EVENTSTORE_PASSWORD}"
