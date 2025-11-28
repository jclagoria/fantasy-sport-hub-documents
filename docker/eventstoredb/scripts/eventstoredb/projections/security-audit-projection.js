// Security Audit Projection
// Tracks security events and identifies suspicious patterns
// Stream: security-audit

fromStream('security-audit')
  .when({
    $init: function() {
      return {
        totalAttempts: 0,
        failedAttempts: 0,
        successfulAttempts: 0,
        unauthorizedAccess: 0,
        userActivity: {},
        suspiciousIPs: {},
        lastEventAt: null
      };
    },

    LoginAttempt: function(state, event) {
      state.totalAttempts += 1;

      const userId = event.data.userId;
      const ipAddress = event.data.ipAddress;

      if (!state.userActivity[userId]) {
        state.userActivity[userId] = {
          userId: userId,
          totalAttempts: 0,
          failedAttempts: 0,
          successfulAttempts: 0,
          lastAttemptAt: null,
          ipAddresses: []
        };
      }

      state.userActivity[userId].totalAttempts += 1;
      state.userActivity[userId].lastAttemptAt = event.data.timestamp;

      if (state.userActivity[userId].ipAddresses.indexOf(ipAddress) === -1) {
        state.userActivity[userId].ipAddresses.push(ipAddress);
      }

      state.lastEventAt = event.data.timestamp;
      return state;
    },

    LoginFailed: function(state, event) {
      state.failedAttempts += 1;

      const userId = event.data.userId;
      const ipAddress = event.data.ipAddress;

      if (state.userActivity[userId]) {
        state.userActivity[userId].failedAttempts += 1;
      }

      // Track suspicious IPs with multiple failures
      if (!state.suspiciousIPs[ipAddress]) {
        state.suspiciousIPs[ipAddress] = {
          ipAddress: ipAddress,
          failedAttempts: 0,
          firstFailureAt: event.data.timestamp,
          lastFailureAt: null
        };
      }

      state.suspiciousIPs[ipAddress].failedAttempts += 1;
      state.suspiciousIPs[ipAddress].lastFailureAt = event.data.timestamp;

      state.lastEventAt = event.data.timestamp;
      return state;
    },

    LoginSuccessful: function(state, event) {
      state.successfulAttempts += 1;

      const userId = event.data.userId;

      if (state.userActivity[userId]) {
        state.userActivity[userId].successfulAttempts += 1;
      }

      state.lastEventAt = event.data.timestamp;
      return state;
    },

    UnauthorizedAccess: function(state, event) {
      state.unauthorizedAccess += 1;

      const userId = event.data.userId;
      const ipAddress = event.data.ipAddress;

      if (state.userActivity[userId]) {
        state.userActivity[userId].unauthorizedAttempts =
          (state.userActivity[userId].unauthorizedAttempts || 0) + 1;
      }

      if (!state.suspiciousIPs[ipAddress]) {
        state.suspiciousIPs[ipAddress] = {
          ipAddress: ipAddress,
          unauthorizedAttempts: 0,
          firstAttemptAt: event.data.timestamp,
          lastAttemptAt: null
        };
      }

      state.suspiciousIPs[ipAddress].unauthorizedAttempts =
        (state.suspiciousIPs[ipAddress].unauthorizedAttempts || 0) + 1;
      state.suspiciousIPs[ipAddress].lastAttemptAt = event.data.timestamp;

      state.lastEventAt = event.data.timestamp;
      return state;
    }
  });
