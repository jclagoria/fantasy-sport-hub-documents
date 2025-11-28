// Player Statistics Projection
// Aggregates all player events for season statistics
// Stream: player-{playerId}

fromStream('$ce-player')
  .when({
    $init: function() {
      return {
        playerId: null,
        season: null,
        sportId: null,
        gamesPlayed: 0,
        totalPoints: 0,
        averagePointsPerGame: 0.0,
        eventCounts: {
          GOL: 0,
          ASISTENCIA: 0,
          TARJETA_AMARILLA: 0,
          TARJETA_ROJA: 0
        },
        lastUpdatedAt: null
      };
    },

    PlayerScored: function(state, event) {
      state.playerId = event.data.playerId;
      state.sportId = event.data.sportId;
      state.eventCounts.GOL += 1;
      state.totalPoints += 10;  // Base points for goal
      state.lastUpdatedAt = event.data.timestamp;

      // Recalculate average
      if (state.gamesPlayed > 0) {
        state.averagePointsPerGame = state.totalPoints / state.gamesPlayed;
      }

      return state;
    },

    PlayerAssisted: function(state, event) {
      state.playerId = event.data.playerId;
      state.sportId = event.data.sportId;
      state.eventCounts.ASISTENCIA += 1;
      state.totalPoints += 5;  // Base points for assist
      state.lastUpdatedAt = event.data.timestamp;

      if (state.gamesPlayed > 0) {
        state.averagePointsPerGame = state.totalPoints / state.gamesPlayed;
      }

      return state;
    },

    PlayerCarded: function(state, event) {
      state.playerId = event.data.playerId;
      state.sportId = event.data.sportId;

      if (event.data.cardType === 'YELLOW') {
        state.eventCounts.TARJETA_AMARILLA += 1;
        state.totalPoints -= 2;
      } else if (event.data.cardType === 'RED') {
        state.eventCounts.TARJETA_ROJA += 1;
        state.totalPoints -= 5;
      }

      state.lastUpdatedAt = event.data.timestamp;

      if (state.gamesPlayed > 0) {
        state.averagePointsPerGame = state.totalPoints / state.gamesPlayed;
      }

      return state;
    },

    BonusAwarded: function(state, event) {
      state.playerId = event.data.playerId;
      state.totalPoints += event.data.points;
      state.lastUpdatedAt = event.data.timestamp;

      if (state.gamesPlayed > 0) {
        state.averagePointsPerGame = state.totalPoints / state.gamesPlayed;
      }

      return state;
    },

    MatchEnded: function(state, event) {
      state.gamesPlayed += 1;

      if (state.gamesPlayed > 0) {
        state.averagePointsPerGame = state.totalPoints / state.gamesPlayed;
      }

      return state;
    }
  });
