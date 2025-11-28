# Frontend Architecture Overview

> Complete frontend architecture of Fantasy Sports Hub with Next.js 14

**Status**: ✅ Active
**Version**: 1.0.1
**Last Updated**: 2025-11-14

---

## 📐 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Browser                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          Next.js 16 App Router (Edge Runtime)            │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                           │  │
│  │  ┌─────────────────┐         ┌──────────────────────┐   │  │
│  │  │ Server          │         │ Client               │   │  │
│  │  │ Components      │────────▶│ Components           │   │  │
│  │  │ (RSC)           │         │ ('use client')       │   │  │
│  │  └─────────────────┘         └──────────────────────┘   │  │
│  │         │                              │                 │  │
│  │         │                              ▼                 │  │
│  │         │                    ┌──────────────────────┐   │  │
│  │         │                    │  State Management    │   │  │
│  │         │                    ├──────────────────────┤   │  │
│  │         │                    │ • TanStack Query     │   │  │
│  │         │                    │   (Server State)     │   │  │
│  │         │                    │ • Zustand            │   │  │
│  │         │                    │   (Client State)     │   │  │
│  │         │                    └──────────────────────┘   │  │
│  │         │                              │                 │  │
│  │         ▼                              ▼                 │  │
│  │  ┌──────────────────────────────────────────────────┐   │  │
│  │  │         Communication Layer                       │   │  │
│  │  ├──────────────────────────────────────────────────┤   │  │
│  │  │ REST API (Axios)  │  WebSocket (SockJS+STOMP)    │   │  │
│  │  └──────────────────────────────────────────────────┘   │  │
│  └──────────────────────┬───────────────┬──────────────────┘  │
│                         │               │                     │
└─────────────────────────┼───────────────┼─────────────────────┘
                          │               │
                          ▼               ▼
          ┌───────────────────────────────────────────┐
          │     Spring Boot WebFlux Backend           │
          ├───────────────────────────────────────────┤
          │  • REST API                               │
          │  • WebSocket /ws endpoint                 │
          │  • Event Sourcing + CQRS                  │
          └───────────────────────────────────────────┘
```

---

## 🏗️ Project Structure

```
frontend/
├── app/                           # Next.js 14 App Router
│   ├── (auth)/                   # Auth route group
│   │   ├── login/
│   │   │   └── page.tsx
│   │   ├── register/
│   │   │   └── page.tsx
│   │   └── layout.tsx
│   │
│   ├── (dashboard)/              # Protected routes
│   │   ├── dashboard/
│   │   │   └── page.tsx
│   │   ├── leagues/
│   │   │   ├── [id]/
│   │   │   │   ├── roster/
│   │   │   │   ├── standings/
│   │   │   │   └── settings/
│   │   │   └── page.tsx
│   │   ├── draft/
│   │   │   └── [roomId]/
│   │   │       └── page.tsx
│   │   └── layout.tsx
│   │
│   ├── api/                      # API Routes (BFF pattern)
│   │   ├── auth/
│   │   │   └── route.ts
│   │   └── health/
│   │       └── route.ts
│   │
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Home page
│   ├── error.tsx                 # Global error boundary
│   ├── loading.tsx               # Global loading
│   └── not-found.tsx             # 404 page
│
├── components/
│   ├── ui/                       # Shadcn/ui base components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── dialog.tsx
│   │   ├── dropdown-menu.tsx
│   │   ├── input.tsx
│   │   ├── select.tsx
│   │   ├── tabs.tsx
│   │   └── toast.tsx
│   │
│   ├── features/                 # Feature-specific components
│   │   ├── roster/
│   │   │   ├── components/
│   │   │   │   ├── PlayerCard/
│   │   │   │   │   ├── PlayerCard.tsx
│   │   │   │   │   ├── PlayerCardStats.tsx
│   │   │   │   │   ├── PlayerCardActions.tsx
│   │   │   │   │   └── PlayerCardSkeleton.tsx
│   │   │   │   ├── RosterGrid/
│   │   │   │   │   ├── RosterGrid.tsx
│   │   │   │   │   ├── StartingLineup.tsx
│   │   │   │   │   ├── BenchSection.tsx
│   │   │   │   │   ├── PositionSlot.tsx
│   │   │   │   │   └── EmptySlot.tsx
│   │   │   │   └── LineupValidator/
│   │   │   │       └── LineupValidator.tsx
│   │   │   ├── hooks/
│   │   │   │   ├── useRoster.ts
│   │   │   │   ├── useRosterDragDrop.ts
│   │   │   │   ├── useRosterValidation.ts
│   │   │   │   └── useRosterSync.ts
│   │   │   └── types/
│   │   │       └── roster.types.ts
│   │   │
│   │   ├── draft/
│   │   │   ├── components/
│   │   │   │   ├── DraftRoom/
│   │   │   │   │   ├── DraftRoom.tsx
│   │   │   │   │   ├── DraftLobby.tsx
│   │   │   │   │   └── DraftComplete.tsx
│   │   │   │   ├── PickTimer/
│   │   │   │   │   └── PickTimer.tsx
│   │   │   │   ├── CurrentPickPanel/
│   │   │   │   │   └── CurrentPickPanel.tsx
│   │   │   │   ├── AvailablePlayerList/
│   │   │   │   │   └── AvailablePlayerList.tsx
│   │   │   │   ├── DraftOrderList/
│   │   │   │   │   └── DraftOrderList.tsx
│   │   │   │   ├── DraftTeamPanel/
│   │   │   │   │   └── DraftTeamPanel.tsx
│   │   │   │   └── DraftChat/
│   │   │   │       └── DraftChat.tsx
│   │   │   ├── hooks/
│   │   │   │   ├── useDraft.ts
│   │   │   │   ├── useDraftPick.ts
│   │   │   │   ├── useDraftSync.ts
│   │   │   │   └── useAutoPickWarning.ts
│   │   │   └── types/
│   │   │       └── draft.types.ts
│   │   │
│   │   ├── scoring/
│   │   │   ├── components/
│   │   │   │   ├── LiveScoreDashboard/
│   │   │   │   ├── MatchTracker/
│   │   │   │   └── EventsFeed/
│   │   │   ├── hooks/
│   │   │   │   ├── useLiveScores.ts
│   │   │   │   └── useLiveSync.ts
│   │   │   └── types/
│   │   │       └── scoring.types.ts
│   │   │
│   │   ├── leagues/
│   │   │   ├── components/
│   │   │   │   ├── LeagueCard/
│   │   │   │   ├── CreateLeagueDialog/
│   │   │   │   └── LeagueSettings/
│   │   │   ├── hooks/
│   │   │   │   ├── useLeague.ts
│   │   │   │   └── useLeagueMembers.ts
│   │   │   └── types/
│   │   │       └── league.types.ts
│   │   │
│   │   └── analytics/
│   │       ├── components/
│   │       │   ├── StatsChart/
│   │       │   └── TrendAnalysis/
│   │       ├── hooks/
│   │       │   └── usePlayerStats.ts
│   │       └── types/
│   │           └── analytics.types.ts
│   │
│   └── shared/                   # Shared components
│       ├── Header/
│       │   └── Header.tsx
│       ├── Footer/
│       │   └── Footer.tsx
│       ├── Navigation/
│       │   └── Navigation.tsx
│       ├── ThemeToggle/
│       │   └── ThemeToggle.tsx
│       └── ErrorBoundary/
│           └── ErrorBoundary.tsx
│
├── lib/
│   ├── api/                      # API client
│   │   ├── client.ts             # Axios instance
│   │   ├── endpoints/
│   │   │   ├── leagues.ts
│   │   │   ├── players.ts
│   │   │   ├── roster.ts
│   │   │   ├── draft.ts
│   │   │   └── scoring.ts
│   │   └── interceptors/
│   │       ├── auth.interceptor.ts
│   │       └── error.interceptor.ts
│   │
│   ├── hooks/                    # Global custom hooks
│   │   ├── useAuth.ts
│   │   ├── useMediaQuery.ts
│   │   ├── useDebounce.ts
│   │   └── useLocalStorage.ts
│   │
│   ├── schemas/                  # Zod validation schemas
│   │   ├── league.schema.ts
│   │   ├── player.schema.ts
│   │   ├── roster.schema.ts
│   │   └── auth.schema.ts
│   │
│   ├── stores/                   # Zustand stores
│   │   ├── authStore.ts
│   │   ├── uiStore.ts
│   │   └── notificationStore.ts
│   │
│   ├── utils/                    # Utility functions
│   │   ├── cn.ts                 # className merge
│   │   ├── format.ts             # Formatting helpers
│   │   ├── validation.ts         # Validation helpers
│   │   └── constants.ts          # Global constants
│   │
│   ├── design-tokens/            # Design system
│   │   ├── colors.ts
│   │   ├── typography.ts
│   │   ├── spacing.ts
│   │   └── animations.ts
│   │
│   └── websocket/                # WebSocket client
│       ├── client.ts             # SockJS + STOMP setup
│       ├── subscriptions.ts      # Topic subscriptions
│       └── handlers.ts           # Message handlers
│
├── types/                        # Global TypeScript types
│   ├── api.types.ts
│   ├── models/
│   │   ├── User.ts
│   │   ├── League.ts
│   │   ├── Player.ts
│   │   ├── Team.ts
│   │   └── Match.ts
│   └── enums/
│       ├── Sport.ts
│       ├── Position.ts
│       └── MatchStatus.ts
│
├── public/                       # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── config/                       # Configuration files
│   ├── site.config.ts
│   └── env.config.ts
│
├── middleware.ts                 # Next.js middleware
├── next.config.mjs              # Next.js config
├── tailwind.config.ts           # Tailwind config
├── postcss.config.js            # PostCSS config
├── tsconfig.json                # TypeScript config
├── .eslintrc.json              # ESLint config
├── .prettierrc                 # Prettier config
├── vitest.config.ts            # Vitest config
├── playwright.config.ts        # Playwright config
└── package.json                # Dependencies
```

---

## 🔄 Data Flow Architecture

### 1. REST API Flow (TanStack Query)

```typescript
// Feature: Roster Management

┌─────────────┐
│   User      │
│  Action     │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Component (Client)                  │
│  const { data, mutate } =            │
│    useRoster(teamId)                 │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Custom Hook                         │
│  useQuery(['roster', teamId], ...)   │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  API Client                          │
│  axios.get('/api/v1/rosters/123')   │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Spring Backend                      │
│  RosterController                    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Response                            │
│  { players: [...], formation: ... }  │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  TanStack Query Cache                │
│  Stores in cache with key            │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Component Re-render                 │
│  UI updates with data                │
└──────────────────────────────────────┘
```

### 2. WebSocket Flow (Real-time Updates)

```typescript
// Feature: Live Scoring

┌──────────────────────────────────────┐
│  Match Event (Backend)               │
│  GOAL scored at 45:23                │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Kafka Event                         │
│  scoring-events topic                │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Spring WebSocket                    │
│  /topic/matches/{matchId}            │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  SockJS + STOMP (Frontend)           │
│  client.subscribe(topic, handler)    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  useLiveScores Hook                  │
│  Receives message                    │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  TanStack Query Integration          │
│  queryClient.invalidateQueries()     │
│  OR setQueryData() optimistic update │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Component Re-render                 │
│  Score updates with animation        │
└──────────────────────────────────────┘
```

### 3. Optimistic Updates Flow

```typescript
// Feature: Trade Submission

┌──────────────┐
│ User submits │
│   trade      │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────┐
│ useMutation onMutate                 │
│ 1. Cancel in-flight queries          │
│ 2. Snapshot current data             │
│ 3. Optimistically update cache       │
└──────┬───────────────────────────────┘
       │
       ├────────────────────────────────┐
       │                                │
       ▼                                ▼
┌──────────────────┐          ┌────────────────────┐
│ UI updates       │          │ API call to        │
│ immediately      │          │ backend            │
└──────────────────┘          └────────┬───────────┘
                                       │
                              ┌────────┴─────────┐
                              │                  │
                              ▼                  ▼
                    ┌──────────────┐   ┌──────────────┐
                    │ Success      │   │ Error        │
                    │ - Keep UI    │   │ - Rollback   │
                    │ - Invalidate │   │ - Show error │
                    └──────────────┘   └──────────────┘
```

---

## 🎯 Key Features Implementation

### Feature 1: Roster Management

**Components**:
- `RosterGrid`: Main container
- `StartingLineup`: Formation-based layout (4-4-2, etc.)
- `BenchSection`: Draggable bench players
- `PositionSlot`: Drop zone with validation
- `PlayerCard`: Draggable player representation

**Hooks**:
- `useRoster`: Fetch roster data (TanStack Query)
- `useRosterDragDrop`: @dnd-kit integration
- `useRosterValidation`: Position/budget validation
- `useRosterSync`: WebSocket sync for multi-device

**State Management**:
- **Server State** (TanStack Query): Roster data, player stats
- **Client State** (Zustand): Drag state, UI preferences

**Real-time**:
- WebSocket subscription: `/topic/rosters/{teamId}`
- Events: `PLAYER_ADDED`, `PLAYER_REMOVED`, `FORMATION_CHANGED`

---

### Feature 2: Draft Room

**Components**:
- `DraftRoom`: Main orchestrator
- `DraftLobby`: Pre-draft waiting room
- `PickTimer`: Countdown with warnings
- `AvailablePlayerList`: Filterable/searchable list
- `DraftOrderList`: Snake draft visualization
- `DraftChat`: Real-time chat
- `DraftComplete`: Post-draft summary

**Hooks**:
- `useDraft`: Draft state (TanStack Query)
- `useDraftPick`: Submit pick mutation
- `useDraftSync`: WebSocket real-time updates
- `useAutoPickWarning`: Warning when time running out

**State Management**:
- **Server State**: Draft configuration, available players
- **Client State**: Filter preferences, chat messages

**Real-time**:
- WebSocket subscription: `/topic/draft/{draftId}`
- Events: `PICK_MADE`, `TIMER_TICK`, `CHAT_MESSAGE`, `AUTO_PICK`

**Key Interactions**:
```typescript
// Pick flow
User drags player → Confirmation modal →
Optimistic update → API call →
WebSocket broadcast → All users see update
```

---

### Feature 3: Live Scoring Dashboard

**Components**:
- `LiveScoreDashboard`: Main dashboard
- `ScoreSummary`: Total points breakdown
- `RivalComparison`: Head-to-head stats
- `MatchTracker`: Live match events
- `LivePlayerCard`: Player with live stats
- `EventsFeed`: Real-time event stream

**Hooks**:
- `useLiveScores`: Subscribe to live scoring
- `useLiveSync`: WebSocket integration
- `useScoreAnimation`: Animate score changes
- `useSoundEffects`: Audio feedback

**State Management**:
- **Server State**: Match data, player stats
- **Client State**: Sound preferences, expanded sections

**Real-time**:
- WebSocket subscription: `/topic/matches/{matchId}`
- Events: `GOAL`, `ASSIST`, `YELLOW_CARD`, `SUBSTITUTION`

**Performance Optimization**:
```typescript
// Batch updates to prevent UI thrashing
const [scoreUpdates, setScoreUpdates] = useState([])

useEffect(() => {
  // Debounce updates every 500ms
  const timer = setTimeout(() => {
    applyBatchedUpdates(scoreUpdates)
    setScoreUpdates([])
  }, 500)

  return () => clearTimeout(timer)
}, [scoreUpdates])
```

---

## 🔐 Authentication Flow

```typescript
┌─────────────┐
│   Login     │
│   Form      │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────┐
│  POST /api/auth/login                │
│  { username, password }              │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Spring Security                     │
│  JWT Generation                      │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Response                            │
│  {                                   │
│    accessToken: "...",               │
│    refreshToken: "...",              │
│    user: { ... }                     │
│  }                                   │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Frontend Storage                    │
│  • accessToken → httpOnly cookie     │
│  • refreshToken → localStorage       │
│  • user → Zustand store              │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Axios Interceptor                   │
│  Attach Bearer token to requests     │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Token Refresh on 401                │
│  1. Detect 401                       │
│  2. Call /api/auth/refresh           │
│  3. Get new tokens                   │
│  4. Retry original request           │
└──────────────────────────────────────┘
```

**Implementation**:

```typescript
// lib/api/interceptors/auth.interceptor.ts
export const setupAuthInterceptor = (axiosInstance: AxiosInstance) => {
  axiosInstance.interceptors.response.use(
    (response) => response,
    async (error) => {
      const originalRequest = error.config

      if (error.response?.status === 401 && !originalRequest._retry) {
        originalRequest._retry = true

        try {
          const refreshToken = localStorage.getItem('refreshToken')
          const { data } = await axios.post('/api/auth/refresh', {
            refreshToken
          })

          // Update tokens
          document.cookie = `accessToken=${data.accessToken}; HttpOnly`
          localStorage.setItem('refreshToken', data.refreshToken)

          // Retry original request
          return axiosInstance(originalRequest)
        } catch (refreshError) {
          // Refresh failed, logout user
          useAuthStore.getState().logout()
          window.location.href = '/login'
        }
      }

      return Promise.reject(error)
    }
  )
}
```

---

## 🎨 Design System Integration

### Tailwind Configuration

```typescript
// tailwind.config.ts
export default {
  darkMode: ['class'],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Brand colors
        brand: {
          primary: '#3B82F6',
          secondary: '#10B981',
          accent: '#F59E0B'
        },

        // Sport-specific colors
        sport: {
          futbol: '#10B981',
          baloncesto: '#F59E0B',
          baseball: '#3B82F6',
          tenis: '#EF4444',
          hockey: '#8B5CF6'
        },

        // Position colors
        position: {
          quarterback: '#8B5CF6',
          running_back: '#10B981',
          wide_receiver: '#3B82F6',
          tight_end: '#F59E0B',
          defense: '#EF4444'
        },

        // Semantic colors
        success: '#10B981',
        warning: '#F59E0B',
        error: '#EF4444',
        info: '#3B82F6'
      },

      keyframes: {
        'score-pulse': {
          '0%, 100%': { transform: 'scale(1)', opacity: '1' },
          '50%': { transform: 'scale(1.2)', opacity: '0.8' }
        },
        'slide-in-right': {
          '0%': { transform: 'translateX(100%)', opacity: '0' },
          '100%': { transform: 'translateX(0)', opacity: '1' }
        }
      },

      animation: {
        'score-pulse': 'score-pulse 0.6s ease-in-out',
        'slide-in-right': 'slide-in-right 0.3s ease-out'
      }
    }
  }
}
```

### CVA Component Variants

```typescript
// components/features/roster/components/PlayerCard/PlayerCard.tsx
import { cva, type VariantProps } from 'class-variance-authority'

const playerCardVariants = cva(
  // Base styles
  'rounded-lg border p-4 transition-all cursor-pointer',
  {
    variants: {
      position: {
        QB: 'border-position-quarterback bg-purple-50 dark:bg-purple-950',
        RB: 'border-position-running_back bg-green-50 dark:bg-green-950',
        WR: 'border-position-wide_receiver bg-blue-50 dark:bg-blue-950',
        TE: 'border-position-tight_end bg-amber-50 dark:bg-amber-950',
        DEF: 'border-position-defense bg-red-50 dark:bg-red-950'
      },

      state: {
        default: 'hover:shadow-md hover:-translate-y-1',
        dragging: 'opacity-50 rotate-2 scale-105 shadow-xl',
        locked: 'opacity-60 cursor-not-allowed',
        injured: 'border-red-500 bg-red-50 dark:bg-red-950'
      },

      size: {
        sm: 'p-2 text-sm',
        md: 'p-4 text-base',
        lg: 'p-6 text-lg'
      }
    },

    defaultVariants: {
      state: 'default',
      size: 'md'
    }
  }
)

export interface PlayerCardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof playerCardVariants> {
  player: Player
}

export const PlayerCard = ({
  player,
  position,
  state,
  size,
  className,
  ...props
}: PlayerCardProps) => {
  return (
    <div
      className={cn(playerCardVariants({ position, state, size }), className)}
      {...props}
    >
      {/* Player content */}
    </div>
  )
}
```

---

## 🧪 Testing Strategy

### Unit Tests (Vitest)

```typescript
// components/features/roster/components/PlayerCard/PlayerCard.test.tsx
import { render, screen } from '@testing-library/react'
import { PlayerCard } from './PlayerCard'

describe('PlayerCard', () => {
  const mockPlayer = {
    id: '1',
    name: 'Patrick Mahomes',
    position: 'QB',
    team: 'KC',
    points: 24.5
  }

  it('renders player name and position', () => {
    render(<PlayerCard player={mockPlayer} position="QB" />)

    expect(screen.getByText('Patrick Mahomes')).toBeInTheDocument()
    expect(screen.getByText('QB')).toBeInTheDocument()
  })

  it('applies correct variant classes', () => {
    const { container } = render(
      <PlayerCard player={mockPlayer} position="QB" state="dragging" />
    )

    expect(container.firstChild).toHaveClass('opacity-50', 'rotate-2')
  })
})
```

### Integration Tests (Testing Library)

```typescript
// components/features/roster/RosterGrid.integration.test.tsx
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClientProvider } from '@tanstack/react-query'
import { RosterGrid } from './components/RosterGrid'

describe('RosterGrid Integration', () => {
  it('allows dragging player from bench to starting lineup', async () => {
    const user = userEvent.setup()
    render(
      <QueryClientProvider client={queryClient}>
        <RosterGrid teamId="team-1" />
      </QueryClientProvider>
    )

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Starting Lineup')).toBeInTheDocument()
    })

    // Drag player
    const player = screen.getByText('Patrick Mahomes')
    const qbSlot = screen.getByTestId('position-slot-QB')

    // Simulate drag and drop
    await user.drag(player, qbSlot)

    // Assert player moved
    expect(qbSlot).toContainElement(player)
  })
})
```

### E2E Tests (Playwright)

```typescript
// e2e/draft-room.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Draft Room', () => {
  test('complete draft pick flow', async ({ page }) => {
    // Login
    await page.goto('/login')
    await page.fill('[name="username"]', 'testuser')
    await page.fill('[name="password"]', 'password')
    await page.click('button[type="submit"]')

    // Navigate to draft room
    await page.goto('/draft/room-123')

    // Wait for draft to load
    await expect(page.locator('text=Draft Room')).toBeVisible()

    // Wait for user's turn
    await expect(page.locator('text=Your Pick')).toBeVisible()

    // Select a player
    await page.click('[data-testid="player-1"]')

    // Confirm pick
    await page.click('button:has-text("Confirm Pick")')

    // Verify success
    await expect(page.locator('text=Pick Confirmed')).toBeVisible()
    await expect(page.locator('[data-testid="my-team"]')).toContainText(
      'Patrick Mahomes'
    )
  })
})
```

---

## 📊 Performance Monitoring

### Core Web Vitals Tracking

```typescript
// lib/analytics/web-vitals.ts
import { onCLS, onFID, onLCP, onFCP, onTTFB } from 'web-vitals'

export const reportWebVitals = () => {
  onCLS(console.log)
  onFID(console.log)
  onLCP(console.log)
  onFCP(console.log)
  onTTFB(console.log)
}

// app/layout.tsx
export default function RootLayout({ children }) {
  useEffect(() => {
    reportWebVitals()
  }, [])

  return <html>{children}</html>
}
```

### Bundle Analysis

```bash
# Analyze bundle size
ANALYZE=true npm run build

# Output: Interactive bundle analyzer in browser
# Shows which dependencies contribute to bundle size
```

---

## 🚀 Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│             Vercel Edge Network                     │
│  (CDN + Edge Runtime + Serverless Functions)        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────┐    ┌───────────────┐           │
│  │  Static Assets│    │ Server        │           │
│  │  (Images, CSS)│    │ Components    │           │
│  │  Cached at    │    │ (Rendered at  │           │
│  │  Edge         │    │  Edge)        │           │
│  └───────────────┘    └───────────────┘           │
│                                                     │
│  ┌───────────────────────────────────┐             │
│  │     API Routes (Serverless)       │             │
│  │     /api/* endpoints              │             │
│  └───────────────────────────────────┘             │
│                                                     │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────┐
        │   Spring Boot Backend            │
        │   (Kubernetes Cluster)           │
        └──────────────────────────────────┘
```

**Environment Variables**:

```bash
# .env.production
NEXT_PUBLIC_API_URL=https://api.fantasysportshub.com
NEXT_PUBLIC_WS_URL=wss://api.fantasysportshub.com/ws
NEXT_PUBLIC_ENVIRONMENT=production
```

---

## 📝 Next Steps

1. ✅ **Stack Approved** (completed)
2. 🚧 **Initialize Project**:
   ```bash
   npx create-next-app@latest fantasy-sports-hub-frontend --typescript --tailwind --app
   cd fantasy-sports-hub-frontend
   npm install
   ```

3. 🚧 **Setup Base Configuration**:
   - Configure Tailwind with design tokens
   - Setup Shadcn/ui components
   - Configure ESLint + Prettier
   - Setup Vitest + Playwright

4. 🚧 **Core Infrastructure**:
   - API client with interceptors
   - WebSocket client setup
   - TanStack Query configuration
   - Zustand stores

5. 🚧 **Feature Implementation** (Prioritized):
   - **Phase 1**: Authentication + Dashboard
   - **Phase 2**: Roster Management (killer feature)
   - **Phase 3**: Draft Room
   - **Phase 4**: Live Scoring
   - **Phase 5**: Analytics

---