// Match Scoring Projection
// Aggregates player events for live score calculation
// Stream: match-{matchId}

fromStream('$ce-match')
  .when({
    $init: function() {
      return {
        matchId: null,
        sportId: null,
        status: 'SCHEDULED',
        startedAt: null,
        finishedAt: null,
        playerEvents: {},
        totalEvents: 0
      };
    },

    MatchStarted: function(state, event) {
      state.matchId = event.data.matchId;
      state.sportId = event.data.sportId;
      state.status = 'IN_PROGRESS';
      state.startedAt = event.data.timestamp;
      return state;
    },

    PlayerScored: function(state, event) {
      const playerId = event.data.playerId;

      if (!state.playerEvents[playerId]) {
        state.playerEvents[playerId] = {
          playerId: playerId,
          goals: 0,
          assists: 0,
          cards: { yellow: 0, red: 0 },
          totalPoints: 0,
          events: []
        };
      }

      state.playerEvents[playerId].goals += 1;
      state.playerEvents[playerId].events.push({
        type: 'GOL',
        minute: event.data.minute,
        timestamp: event.data.timestamp,
        points: 10  // Base points for goal
      });
      state.playerEvents[playerId].totalPoints += 10;
      state.totalEvents += 1;

      return state;
    },

    PlayerAssisted: function(state, event) {
      const playerId = event.data.playerId;

      if (!state.playerEvents[playerId]) {
        state.playerEvents[playerId] = {
          playerId: playerId,
          goals: 0,
          assists: 0,
          cards: { yellow: 0, red: 0 },
          totalPoints: 0,
          events: []
        };
      }

      state.playerEvents[playerId].assists += 1;
      state.playerEvents[playerId].events.push({
        type: 'ASISTENCIA',
        minute: event.data.minute,
        timestamp: event.data.timestamp,
        points: 5  // Base points for assist
      });
      state.playerEvents[playerId].totalPoints += 5;
      state.totalEvents += 1;

      return state;
    },

    PlayerCarded: function(state, event) {
      const playerId = event.data.playerId;
      const cardType = event.data.cardType; // 'YELLOW' or 'RED'

      if (!state.playerEvents[playerId]) {
        state.playerEvents[playerId] = {
          playerId: playerId,
          goals: 0,
          assists: 0,
          cards: { yellow: 0, red: 0 },
          totalPoints: 0,
          events: []
        };
      }

      if (cardType === 'YELLOW') {
        state.playerEvents[playerId].cards.yellow += 1;
        state.playerEvents[playerId].totalPoints -= 2;  // Penalty for yellow card
        state.playerEvents[playerId].events.push({
          type: 'TARJETA_AMARILLA',
          minute: event.data.minute,
          timestamp: event.data.timestamp,
          points: -2
        });
      } else if (cardType === 'RED') {
        state.playerEvents[playerId].cards.red += 1;
        state.playerEvents[playerId].totalPoints -= 5;  // Penalty for red card
        state.playerEvents[playerId].events.push({
          type: 'TARJETA_ROJA',
          minute: event.data.minute,
          timestamp: event.data.timestamp,
          points: -5
        });
      }

      state.totalEvents += 1;
      return state;
    },

    LiveScoreCalculated: function(state, event) {
      const playerId = event.data.playerId;

      if (state.playerEvents[playerId]) {
        state.playerEvents[playerId].totalPoints = event.data.points;
      }

      return state;
    },

    MatchEnded: function(state, event) {
      state.status = 'FINISHED';
      state.finishedAt = event.data.timestamp;
      return state;
    }
  });
