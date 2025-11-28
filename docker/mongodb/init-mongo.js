// MongoDB Initialization Script for Fantasy Sports Hub

// Create database and collections
db = db.getSiblingDB('fantasy_sports_hub');

// Create collections with validation
const collections = [
  'match_projections',
  'team_week_projections',
  'player_stats',
  'league_standings',
  'transaction_audit',
  'user_activity',
  'system_metrics'
];

collections.forEach(collName => {
  db.createCollection(collName, {
    validator: {
      $jsonSchema: {
        bsonType: 'object',
        required: ['_id', 'createdAt'],
        properties: {
          createdAt: { bsonType: 'date' },
          updatedAt: { bsonType: 'date' }
        }
      }
    }
  });
});

// Create indexes for match_projections
db.match_projections.createIndex({ matchId: 1 }, { unique: true });
db.match_projections.createIndex({ sportId: 1, status: 1 });
db.match_projections.createIndex({ 'homeTeam.id': 1 });
db.match_projections.createIndex({ 'awayTeam.id': 1 });
db.match_projections.createIndex({ 'playerEvents.playerId': 1 });

// Create indexes for team_week_projections
db.team_week_projections.createIndex({ teamId: 1, weekId: 1 }, { unique: true });
db.team_week_projections.createIndex({ leagueId: 1, weekId: 1 });

// Create indexes for player_stats
db.player_stats.createIndex({ playerId: 1, leagueId: 1 }, { unique: true });
db.player_stats.createIndex({ teamId: 1 });

// Create indexes for league_standings
db.league_standings.createIndex({ leagueId: 1 }, { unique: true });

// Cambiar a 'admin' para crear el usuario
db = db.getSiblingDB('admin');

// Create admin user for the application
db.createUser({
  user: 'fantasy_app',
  pwd: 'fantasy_app_password',
  roles: [
    { role: 'readWrite', db: 'fantasy_sports_hub' }
  ]
});

print('MongoDB initialization completed successfully!');
