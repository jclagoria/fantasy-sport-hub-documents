# REST API Specification - API Specification

> **OpenAPI 3.1 Compliant**: API RESTful con documentación completa

---

## 🎯 API Design Principles

- **RESTful**: Well-defined resources with semantic HTTP verbs
- **Versioning**: URL-based versioning (`/api/v1/...`)
- **Pagination**: Cursor-based pagination for large datasets
- **Filtering**: Query parameters for flexible filtering
- **Sorting**: Multi-field sorting support
- **HATEOAS**: Hypermedia links in responses (Richardson level 3)
- **Error Handling**: Consistent error response format
- **Rate Limiting**: 1000 requests/hour per user

---

## 📚 OpenAPI Specification

### Base Configuration

```yaml
openapi: 3.1.0
info:
  title: Fantasy Sports Hub API
  description: Multi-sport fantasy league management platform
  version: 1.0.0
  contact:
    name: API Support
    email: api@fantasy-sports.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: https://api.fantasy-sports.com/v1
    description: Production server
  - url: https://staging-api.fantasy-sports.com/v1
    description: Staging server
  - url: http://localhost:8080/v1
    description: Development server

security:
  - BearerAuth: []

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

---

## 👤 Authentication Endpoints

### POST /auth/register

```yaml
/auth/register:
  post:
    summary: Register new user
    tags: [Authentication]
    security: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [email, password]
            properties:
              email:
                type: string
                format: email
                example: user@example.com
              password:
                type: string
                format: password
                minLength: 8
                example: SecurePass123!
              phoneNumber:
                type: string
                pattern: '^\+[1-9]\d{1,14}$'
                example: +1234567890
    responses:
      '201':
        description: User registered successfully
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: string
                  format: uuid
                email:
                  type: string
                createdAt:
                  type: string
                  format: date-time
      '400':
        $ref: '#/components/responses/BadRequest'
      '409':
        description: Email already exists
```

### POST /auth/login

```yaml
/auth/login:
  post:
    summary: Login user
    tags: [Authentication]
    security: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [email, password]
            properties:
              email:
                type: string
                format: email
              password:
                type: string
              mfaCode:
                type: string
                pattern: '^\d{6}$'
                description: Required if MFA is enabled
    responses:
      '200':
        description: Login successful
        content:
          application/json:
            schema:
              type: object
              properties:
                accessToken:
                  type: string
                  example: eyJhbGciOiJIUzUxMiJ9...
                refreshToken:
                  type: string
                expiresIn:
                  type: integer
                  example: 3600
                tokenType:
                  type: string
                  example: Bearer
      '401':
        $ref: '#/components/responses/Unauthorized'
      '403':
        description: MFA code required
```

---

## 🏆 League Endpoints

### GET /leagues

```yaml
/leagues:
  get:
    summary: List leagues
    tags: [Leagues]
    parameters:
      - name: sportId
        in: query
        schema:
          type: string
          enum: [FUTBOL, BALONCESTO, BASEBALL, TENIS, HOCKEY]
      - name: status
        in: query
        schema:
          type: string
          enum: [DRAFT, ACTIVE, FINISHED]
      - name: cursor
        in: query
        description: Cursor for pagination
        schema:
          type: string
      - name: limit
        in: query
        schema:
          type: integer
          minimum: 1
          maximum: 100
          default: 20
    responses:
      '200':
        description: List of leagues
        content:
          application/json:
            schema:
              type: object
              properties:
                data:
                  type: array
                  items:
                    $ref: '#/components/schemas/League'
                pagination:
                  $ref: '#/components/schemas/CursorPagination'
```

### POST /leagues

```yaml
/leagues:
  post:
    summary: Create new league
    tags: [Leagues]
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [name, sportId, maxTeams, leagueType]
            properties:
              name:
                type: string
                minLength: 3
                maxLength: 50
                example: Champions League 2025
              sportId:
                type: string
                enum: [FUTBOL, BALONCESTO, BASEBALL]
              maxTeams:
                type: integer
                minimum: 2
                maximum: 100
                example: 10
              leagueType:
                type: string
                enum: [HEAD_TO_HEAD, ROTISSERIE, POINTS]
              draftDate:
                type: string
                format: date-time
              settings:
                type: object
                properties:
                  playoffTeams:
                    type: integer
                    default: 4
                  tradeDeadlineWeek:
                    type: integer
                    default: 10
    responses:
      '201':
        description: League created
        headers:
          Location:
            schema:
              type: string
            description: URL of created league
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/League'
```

### GET /leagues/{leagueId}

```yaml
/leagues/{leagueId}:
  get:
    summary: Get league details
    tags: [Leagues]
    parameters:
      - name: leagueId
        in: path
        required: true
        schema:
          type: string
          format: uuid
    responses:
      '200':
        description: League details
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/LeagueDetailed'
      '404':
        $ref: '#/components/responses/NotFound'
```

---

## 👥 Team Endpoints

### GET /leagues/{leagueId}/teams

```yaml
/leagues/{leagueId}/teams:
  get:
    summary: List teams in league
    tags: [Teams]
    parameters:
      - $ref: '#/components/parameters/LeagueId'
    responses:
      '200':
        description: List of teams
        content:
          application/json:
            schema:
              type: array
              items:
                $ref: '#/components/schemas/Team'
```

### POST /leagues/{leagueId}/teams

```yaml
/leagues/{leagueId}/teams:
  post:
    summary: Create team in league
    tags: [Teams]
    parameters:
      - $ref: '#/components/parameters/LeagueId'
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [name]
            properties:
              name:
                type: string
                minLength: 3
                maxLength: 30
                example: FC Barcelona Fantasy
    responses:
      '201':
        description: Team created
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Team'
      '409':
        description: League is full
```

### GET /teams/{teamId}/roster

```yaml
/teams/{teamId}/roster:
  get:
    summary: Get team roster
    tags: [Teams]
    parameters:
      - name: teamId
        in: path
        required: true
        schema:
          type: string
          format: uuid
      - name: weekId
        in: query
        schema:
          type: string
          format: uuid
    responses:
      '200':
        description: Team roster
        content:
          application/json:
            schema:
              type: object
              properties:
                teamId:
                  type: string
                  format: uuid
                weekId:
                  type: string
                  format: uuid
                starters:
                  type: array
                  items:
                    $ref: '#/components/schemas/RosterEntry'
                bench:
                  type: array
                  items:
                    $ref: '#/components/schemas/RosterEntry'
                totalPoints:
                  type: number
                  format: double
```

---

## 🔄 Trade Endpoints

### POST /trades

```yaml
/trades:
  post:
    summary: Propose trade
    tags: [Trades]
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [offeringTeamId, receivingTeamId, offeredPlayers, requestedPlayers]
            properties:
              offeringTeamId:
                type: string
                format: uuid
              receivingTeamId:
                type: string
                format: uuid
              offeredPlayers:
                type: array
                items:
                  type: string
                  format: uuid
                minItems: 1
                maxItems: 5
              requestedPlayers:
                type: array
                items:
                  type: string
                  format: uuid
                minItems: 1
                maxItems: 5
              message:
                type: string
                maxLength: 500
    responses:
      '201':
        description: Trade proposed
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Trade'
      '400':
        description: Invalid trade (roster constraints violated)
```

### PUT /trades/{tradeId}/accept

```yaml
/trades/{tradeId}/accept:
  put:
    summary: Accept trade
    tags: [Trades]
    parameters:
      - name: tradeId
        in: path
        required: true
        schema:
          type: string
          format: uuid
    responses:
      '200':
        description: Trade accepted
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Trade'
      '403':
        description: Not authorized to accept this trade
      '409':
        description: Trade no longer valid
```

---

## 📊 Scoring Endpoints

### GET /matches/{matchId}/live-scores

```yaml
/matches/{matchId}/live-scores:
  get:
    summary: Get live match scores
    tags: [Scoring]
    parameters:
      - name: matchId
        in: path
        required: true
        schema:
          type: string
    responses:
      '200':
        description: Live scores
        content:
          application/json:
            schema:
              type: object
              properties:
                matchId:
                  type: string
                status:
                  type: string
                  enum: [SCHEDULED, LIVE, FINISHED]
                homeScore:
                  type: integer
                awayScore:
                  type: integer
                playerScores:
                  type: array
                  items:
                    type: object
                    properties:
                      playerId:
                        type: string
                        format: uuid
                      playerName:
                        type: string
                      totalPoints:
                        type: number
                      events:
                        type: array
                        items:
                          type: object
                          properties:
                            type:
                              type: string
                            points:
                              type: number
                            minute:
                              type: integer
```

### GET /leagues/{leagueId}/standings

```yaml
/leagues/{leagueId}/standings:
  get:
    summary: Get league standings
    tags: [Scoring]
    parameters:
      - $ref: '#/components/parameters/LeagueId'
      - name: weekId
        in: query
        schema:
          type: string
          format: uuid
    responses:
      '200':
        description: League standings
        content:
          application/json:
            schema:
              type: array
              items:
                type: object
                properties:
                  rank:
                    type: integer
                  teamId:
                    type: string
                    format: uuid
                  teamName:
                    type: string
                  wins:
                    type: integer
                  losses:
                    type: integer
                  ties:
                    type: integer
                  totalPoints:
                    type: number
                  _links:
                    type: object
                    properties:
                      self:
                        type: string
                        format: uri
                      team:
                        type: string
                        format: uri
```

---

## 🎲 Waiver Endpoints

### POST /waivers

```yaml
/waivers:
  post:
    summary: Submit waiver claim
    tags: [Waivers]
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [teamId, addPlayerId, dropPlayerId, priority]
            properties:
              teamId:
                type: string
                format: uuid
              addPlayerId:
                type: string
                format: uuid
              dropPlayerId:
                type: string
                format: uuid
              priority:
                type: integer
                minimum: 1
    responses:
      '201':
        description: Waiver claim submitted
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/WaiverClaim'
```

---

## 📋 Common Schemas

```yaml
components:
  schemas:
    League:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        sportId:
          type: string
        commissionerId:
          type: string
          format: uuid
        maxTeams:
          type: integer
        currentTeams:
          type: integer
        status:
          type: string
          enum: [DRAFT, ACTIVE, FINISHED]
        createdAt:
          type: string
          format: date-time
        _links:
          type: object
          properties:
            self:
              type: string
              format: uri
            teams:
              type: string
              format: uri
            standings:
              type: string
              format: uri

    Team:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        ownerId:
          type: string
          format: uuid
        leagueId:
          type: string
          format: uuid
        wins:
          type: integer
        losses:
          type: integer
        totalPoints:
          type: number

    Trade:
      type: object
      properties:
        id:
          type: string
          format: uuid
        offeringTeamId:
          type: string
          format: uuid
        receivingTeamId:
          type: string
          format: uuid
        offeredPlayers:
          type: array
          items:
            type: string
            format: uuid
        requestedPlayers:
          type: array
          items:
            type: string
            format: uuid
        status:
          type: string
          enum: [PENDING, ACCEPTED, REJECTED, CANCELLED]
        proposedAt:
          type: string
          format: date-time

    RosterEntry:
      type: object
      properties:
        playerId:
          type: string
          format: uuid
        playerName:
          type: string
        position:
          type: string
        status:
          type: string
          enum: [STARTER, BENCH, IR]
        weekPoints:
          type: number

    CursorPagination:
      type: object
      properties:
        nextCursor:
          type: string
          nullable: true
        hasMore:
          type: boolean
        _links:
          type: object
          properties:
            next:
              type: string
              format: uri
              nullable: true

    Error:
      type: object
      properties:
        error:
          type: string
        message:
          type: string
        timestamp:
          type: string
          format: date-time
        path:
          type: string
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
              message:
                type: string

  responses:
    BadRequest:
      description: Bad request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

    Unauthorized:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

  parameters:
    LeagueId:
      name: leagueId
      in: path
      required: true
      schema:
        type: string
        format: uuid
```

---

## 🚦 Rate Limiting

### Headers

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1699564800
```

### Rate Limit Response

```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Please try again later.",
  "retryAfter": 3600
}
```

---

## 📖 API Examples

### Complete User Flow

```bash
# 1. Register
curl -X POST https://api.fantasy-sports.com/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }'

# 2. Login
curl -X POST https://api.fantasy-sports.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }'

# Response:
# {
#   "accessToken": "eyJhbGc...",
#   "refreshToken": "abc123...",
#   "expiresIn": 3600
# }

# 3. Create League
curl -X POST https://api.fantasy-sports.com/v1/leagues \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Fantasy League",
    "sportId": "FUTBOL",
    "maxTeams": 10,
    "leagueType": "HEAD_TO_HEAD"
  }'

# 4. Join League
curl -X POST https://api.fantasy-sports.com/v1/leagues/{leagueId}/teams \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "FC Dream Team"
  }'

# 5. Get Live Standings
curl -X GET https://api.fantasy-sports.com/v1/leagues/{leagueId}/standings \
  -H "Authorization: Bearer eyJhbGc..."
```

---
