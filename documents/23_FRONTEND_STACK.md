# Frontend Technology Stack

> Official technology stack decision for the Fantasy Sports Hub frontend

**Status**: ✅ Approved
**Date**: 2025-11-09
**Authors**: Architecture Team
**Version**: 1.0.0

---

## 📋 Stack Overview

### Core Technologies

| Category            | Technology           | Version | Justification |
|---------------------|----------------------|---------|---------------|
| **Framework**       | Next.js              | 16.0.3  | SSR, RSC, App Router, Edge Runtime |
| **UI Library**      | React                | 19.2.0  | Server Components, Suspense, Concurrent Features |
| **Language**        | TypeScript           | 5.9.3   | Type Safety, Developer Experience |
| **State Management**| TanStack Query v5    | 5.90.9  | Server state, cache, optimistic updates |
| **Client State**    | Zustand              | 5.0.8   | Lightweight UI state |
| **Real-time**       | SockJS + STOMP       | 1.6.1 / 7.2.1 | Spring WebFlux compatibility |
| **Styling**         | Tailwind CSS         | 4.1.17  | Utility-first, design tokens |
| **UI Components**   | Radix UI             | Various | Accessible, unstyled components |
| **Drag & Drop**     | @dnd-kit            | 6.3.1   | Touch-friendly, accessible |
| **Forms**           | React Hook Form + Zod| 7.66.0 / 4.1.12 | Performance, type-safe validation |
| **Charts**          | Recharts             | 3.4.1   | Composable React charts |
| **Animations**      | Framer Motion        | 12.23.24 | Declarative animations |
| **Date Handling**   | date-fns             | 4.1.0   | Date utilities |
| **Confetti**        | canvas-confetti      | 1.9.4   | Celebration effects |
| **Build Tools**     | Biome                | 2.3.5   | Linting and formatting |
| **Testing**         | Vitest + Playwright  | 4.0.9 / 1.56.1 | Unit and E2E testing |

---

## 🏗️ Architecture Decisions

### Framework: Next.js 14+ (App Router)

**Decision**: Next.js with App Router as the main frontend framework

**Context**:
- Complex system with dashboards, roster management, real-time draft
- Need for SEO on landing pages and public leagues
- 100K+ concurrent users requires optimal performance
- Clear path to React Native for future mobile apps

**Options Considered**:

#### Option A: Remix
**Pros**:
- Excellent data handling with loaders/actions
- Native nested routing
- Optimistic UI patterns

**Cons**:
- Smaller ecosystem for WebSocket/real-time
- Less adoption than Next.js
- No built-in Edge Runtime

#### Option B: SvelteKit
**Pros**:
- Smaller bundle size
- Excellent performance
- Simpler syntax

**Cons**:
- Less corporate adoption
- Smaller ecosystem
- Difficult migration to native (no React Native)

#### Option C: Astro
**Pros**:
- Excellent for static content
- Islands architecture
- Multi-framework support

**Cons**:
- Not designed for complex real-time applications
- Better for marketing sites than SaaS

#### Option D: Next.js 14+ App Router ✅ **SELECTED**

**Pros**:
- **SSR + RSC**: Improves SEO and initial performance
- **Streaming**: Compatible with Spring WebFlux reactive streams
- **API Routes**: BFF pattern to transform backend data
- **Edge Runtime**: Global CDN for scalability
- **React Server Components**: Reduces bundle size, server-side data fetching
- **Suspense + Streaming**: Declarative loading states
- **React Native Migration**: Reuse of hooks, logic, headless components
- **Mature Ecosystem**: Wide adoption, documentation, hiring

**Cons**:
- Learning curve for App Router (vs Pages Router)
- Initial complexity with Server/Client Components

**Consequences**:

**Positive**:
- Optimal performance with SSR + Edge caching
- Excellent SEO for public leagues
- Clear path to mobile with React Native
- Superior Developer Experience

**Negative**:
- Team needs to learn Server Components paradigm
- More complex debugging (server vs client)

**Mitigations**:
- Training on App Router patterns
- Document Server/Client Components boundaries
- Linting rules to avoid common errors

---

### State Management: TanStack Query v5 + Zustand

**Decision**: Separation of concerns with TanStack Query for server state and Zustand for client state

**Context**:
- Reactive backend (Spring WebFlux) with real-time events
- Need for optimistic updates for smooth UX
- Complex synchronization between WebSocket events and REST API
- Simple client state (modals, UI preferences, drag states)

**Architecture**:

```typescript
// Server State (TanStack Query)
- REST API cache
- WebSocket event sync
- Optimistic updates
- Automatic invalidation

// Client State (Zustand)
- UI state (modals, drawers)
- User preferences (theme, language)
- Transient state (drag & drop)
- Temporary form state
```

**Options Considered**:

#### Option A: Redux Toolkit
**Pros**:
- Well-known pattern
- Redux DevTools
- Middleware ecosystem

**Cons**:
- Excessive boilerplate even with RTK
- RTK Query less mature than TanStack Query
- Overkill for simple state

#### Option B: Jotai / Recoil
**Pros**:
- Atomic state management
- Excellent for derived state
- Less boilerplate

**Cons**:
- Less mature for real-time sync
- Smaller ecosystem

#### Option C: Context API Only
**Pros**:
- Built-in, no dependencies
- Simple for basic cases

**Cons**:
- No caching
- No optimistic updates
- Performance issues with frequent updates

#### Option D: TanStack Query + Zustand ✅ **SELECTED**

**TanStack Query Pros**:
- **Smart cache**: Reduces backend calls
- **Optimistic updates**: Smooth UX for trades, picks
- **Automatic invalidation**: Syncs with WebSocket events
- **Streaming support**: Compatible with WebFlux reactive streams
- **DevTools**: Cache and query debugging
- **Prefetching**: Improves perceived performance

**Zustand Pros**:
- **Lightweight**: <1KB minified
- **Simple API**: No boilerplate
- **Middleware**: Persist, DevTools, Immer
- **No provider wrapper**: Less nesting

**Cons**:
- Two libraries for state (conceptual complexity)
- Team needs to understand separation of concerns

**Consequences**:

**Positive**:
- Optimized cache reduces backend load
- Smooth UX with optimistic updates
- Easy REST + WebSocket synchronization
- Optimal performance (only necessary re-renders)

**Negative**:
- Learning curve for separating server/client state
- Debugging requires understanding two systems

**Mitigations**:
- Document patterns for when to use each
- Add code examples to project docs
- Linting rules to detect misuse

---

### Real-time: SockJS + STOMP

**Decision**: SockJS + STOMP for WebSocket communication with Spring Backend

**Context**:
- Backend uses Spring WebFlux with WebSocket support
- Real-time needs for:
  - Live scoring updates
  - Draft room (real-time picks)
  - League chat
  - Push notifications
- Fallback needed for restrictive networks (corporate firewalls)

**Options Considered**:

#### Option A: Socket.io
**Pros**:
- Very popular in Node.js ecosystem
- Automatic fallbacks
- Rooms and namespaces

**Cons**:
- **Not natively compatible with Spring WebSocket**
- Requires additional Node.js server as proxy
- Infrastructure overhead

#### Option B: Native WebSocket API
**Pros**:
- Browser standard
- No dependencies
- Maximum control

**Cons**:
- No automatic fallback to long-polling
- Manual reconnection handling
- No protocol over WebSocket (raw messages)

#### Option C: Server-Sent Events (SSE)
**Pros**:
- Simple for server-to-client
- Built-in reconnection
- HTTP/2 multiplexing

**Cons**:
- **Unidirectional** (doesn't work for draft picks, chat)
- Limited concurrent connections
- No binary data support

#### Option D: SockJS + STOMP ✅ **SELECTED**

**Pros**:
- **Native Spring WebSocket compatibility**: No additional proxy needed
- **Automatic fallback**: WebSocket → XHR streaming → XHR polling
- **STOMP protocol**: Pub/sub pattern, topic subscriptions
- **Stable library**: Battle-tested with Spring Boot
- **Automatic reconnection**: Resilient to network issues
- **Message acknowledgment**: Delivery guarantees

**Cons**:
- SockJS overhead vs native WebSocket
- More complex debugging with fallbacks

**Integration with TanStack Query**:

```typescript
// Hook pattern to sync WebSocket → TanStack Query
const useLiveScores = (matchId: string) => {
  const queryClient = useQueryClient()

  useEffect(() => {
    const client = new SockJS('/ws')
    const stompClient = Stomp.over(client)

    const subscription = stompClient.subscribe(
      `/topic/matches/${matchId}/scores`,
      (message) => {
        const scoreUpdate = JSON.parse(message.body)
        queryClient.setQueryData(['match', matchId], scoreUpdate)
      }
    )

    return () => subscription.unsubscribe()
  }, [matchId])
}
```

**Consequences**:

**Positive**:
- Smooth real-time experience
- Consistent synchronization across browsers
- Lower latency than polling
- Works behind corporate firewalls

**Negative**:
- Offline/online sync complexity
- Handling duplicate messages
- More complex testing

**Mitigations**:
- Use `react-query` for offline state management
- Implement message deduplication
- E2E tests with Cypress for WebSocket flows

---

### UI Components: Radix UI + @dnd-kit + Tailwind

**Decision**: Accessible components + drag & drop + CSS utilities

**Context**:
- WCAG 2.1 AA accessibility requirements
- Drag & drop for draft and team management
- Effortless consistent design
- Dark mode support

**Options Considered**:

#### Option A: MUI (Material-UI)
**Pros**:
- Rich, customizable components
- Powerful theming
- Large ecosystem

**Cons**:
- Large bundle size
- Proprietary styles (JSS) that may conflict
- Less flexible for custom designs

#### Option B: Headless UI + Tailwind
**Pros**:
- Minimal bundle size
- Total style control
- Excellent accessibility

**Cons**:
- More boilerplate code
- Fewer pre-built components

#### Option C: Radix UI + @dnd-kit + Tailwind ✅ **SELECTED**

**Radix UI Pros**:
- **Accessibility**: Accessible by default
- **Unstyled**: Total visual control with Tailwind
- **Composable**: Flexible and predictable API
- **Bundle size**: ~20KB gzip
- **No CSS runtime**: Zero-runtime CSS-in-JS

**@dnd-kit Pros**:
- **Modular**: Only import what you need
- **Accessible**: Full ARIA support
- **Customizable**: Drag handles, drop zones, etc.
- **Performance**: Uses CSS transforms for animations

**Tailwind Pros**:
- **Productivity**: Rapid design without leaving JSX
- **Consistency**: Unified design tokens
- **PurgeCSS**: Removes unused styles
- **Dark mode**: First-class support

**Cons**:
- Learning curve for Tailwind
- Many configuration files
- Requires design conventions

**Implementation**:

```typescript
// Example: Draggable player component
const DraggablePlayer = ({ player, onDrop }) => {
  const { attributes, listeners, setNodeRef, transform } = useDraggable({
    id: `player-${player.id}`,
    data: { player }
  })

  return (
    <div
      ref={setNodeRef}
      {...listeners}
      {...attributes}
      className="p-4 bg-white rounded-lg shadow-md cursor-move hover:shadow-lg transition-shadow"
      style={{
        transform: transform 
          ? `translate3d(${transform.x}px, ${transform.y}px, 0)` 
          : 'none'
      }}
    >
      <div className="flex items-center space-x-4">
        <Avatar 
          src={player.avatarUrl} 
          alt={player.name} 
          className="w-12 h-12"
        />
        <div>
          <h3 className="font-semibold">{player.name}</h3>
          <p className="text-sm text-gray-600">{player.position}</p>
        </div>
      </div>
    </div>
  )
}
```

**Consequences**:

**Positive**:
- Excellent accessibility from day one
- High performance even with large lists
- Easy maintenance (co-located styles)
- Visual consistency

**Negative**:
- Team needs to learn Tailwind
- Complex initial setup

**Mitigations**:
- Document design conventions
- Create a design system with base components
- Use `twin.macro` for complex styles

---

### Drag & Drop: @dnd-kit

**Decision**: @dnd-kit for drag & drop functionality
**Decisión**: @dnd-kit para funcionalidad drag & drop de roster management y draft

**Contexto**:
- Feature crítico: Roster/Lineup management con drag & drop
- Draft room con drag de jugadores
- Soporte mobile (touch events)
- Accesibilidad (keyboard navigation)

**Opciones Consideradas**:

#### Opción A: react-beautiful-dnd
**Pros**:
- Muy popular históricamente
- Excelente UX

**Contras**:
- **Deprecado/no mantenido**
- No soporte React 18+
- No optimizado para touch

#### Opción B: react-dnd
**Pros**:
- Flexible, bajo nivel
- HTML5 drag & drop API

**Contras**:
- Complejidad alta
- Touch support requiere backend adicional
- DX no tan bueno

#### Opción C: @dnd-kit ✅ **ELEGIDA**

**Pros**:
- **Touch-friendly**: Soporte móvil nativo
- **Accesibilidad**: Keyboard navigation, screen readers
- **Performance**: Virtualización para listas grandes
- **Modular**: Solo importas lo que necesitas
- **Hooks-based**: Modern React patterns
- **Activamente mantenido**: Compatible React 18+
- **Sensores customizables**: Touch, mouse, keyboard

**Contras**:
- Menos maduro que react-beautiful-dnd
- Documentación puede ser mejor

**Uso en Features**:

```typescript
// Roster Management
- Drag players entre Starting Lineup ↔ Bench
- Validación de posiciones (ej: no arrastrar QB a WR slot)
- Visual feedback durante drag

// Draft Room
- Drag player desde Available Players → My Team
- Auto-scroll en listas largas
- Multi-touch support para tablets
```

**Consecuencias**:

**Positivas**:
- UX fluido en desktop y móvil
- Accesibilidad garantizada
- Performance con listas grandes (virtualización)

**Negativas**:
- Curva aprendizaje modular architecture

**Mitigaciones**:
- Crear custom hooks para casos comunes
- Documentar patterns en codebase

---

### Forms & Validation: React Hook Form + Zod

**Decisión**: React Hook Form para forms, Zod para validación

**Contexto**:
- Forms complejos: League settings, trade proposals, draft configurations
- Validación client-side + server-side sync
- Type safety end-to-end
- Performance crítico (re-renders mínimos)

**Opciones Consideradas**:

#### Opción A: Formik + Yup
**Pros**:
- Patrón conocido
- Ecosistema maduro

**Contras**:
- **Controlled inputs** = más re-renders
- Performance inferior
- Yup no tiene type inference de TypeScript

#### Opción B: React Hook Form + Yup
**Pros**:
- Performance de RHF
- Yup familiar

**Contras**:
- Yup sin type inference
- Validación runtime only

#### Opción C: React Hook Form + Zod ✅ **ELEGIDA**

**React Hook Form Pros**:
- **Uncontrolled inputs**: Re-renders mínimos
- **Performance**: Hasta 3x más rápido que Formik
- **Bundle size**: ~9KB (vs 21KB Formik)
- **DevTools**: Debugging de form state

**Zod Pros**:
- **Type inference**: Runtime validation + TypeScript types
- **Composable schemas**: Reutilizar validaciones
- **Error messages**: Customizables
- **Backend sync**: Mismos schemas que Spring Boot DTOs

**Ejemplo de Schema Compartido**:

```typescript
// frontend/lib/schemas/league.schema.ts
export const createLeagueSchema = z.object({
  name: z.string().min(3).max(50),
  sport: z.enum(['FUTBOL', 'BALONCESTO', 'BASEBALL']),
  maxTeams: z.number().min(4).max(16),
  scoringType: z.enum(['STANDARD', 'PPR', 'CUSTOM'])
})

export type CreateLeagueDto = z.infer<typeof createLeagueSchema>

// backend puede usar equivalente Java validation
// que mapee a los mismos constraints
```

**Contras**:
- Curva aprendizaje Zod schemas

**Consecuencias**:

**Positivas**:
- Performance óptimo (minimal re-renders)
- Type safety end-to-end
- Validación consistente frontend/backend

**Negativas**:
- Dos libraries para aprender

**Mitigaciones**:
- Schema library compartida entre forms
- Ejemplos de patterns comunes

---

## 📦 Dependencies Complete List

### Production Dependencies

```json
{
  "dependencies": {
    // Framework & Core
    "next": "^14.2.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "typescript": "^5.4.0",

    // State Management
    "@tanstack/react-query": "^5.28.0",
    "@tanstack/react-query-devtools": "^5.28.0",
    "zustand": "^4.5.0",

    // Real-time
    "sockjs-client": "^1.6.1",
    "@stomp/stompjs": "^7.0.0",

    // UI Components & Styling
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-tooltip": "^1.0.7",
    "@radix-ui/react-popover": "^1.0.7",
    "tailwindcss": "^3.4.0",
    "tailwind-merge": "^2.2.0",
    "clsx": "^2.1.0",
    "class-variance-authority": "^0.7.0",

    // Drag & Drop
    "@dnd-kit/core": "^6.1.0",
    "@dnd-kit/sortable": "^8.0.0",
    "@dnd-kit/utilities": "^3.2.2",

    // Forms & Validation
    "react-hook-form": "^7.51.0",
    "@hookform/resolvers": "^3.3.4",
    "zod": "^3.22.4",

    // Data Visualization
    "recharts": "^2.12.0",

    // Animations
    "framer-motion": "^11.0.0",
    "canvas-confetti": "^1.9.2",

    // Utilities
    "date-fns": "^3.3.0",
    "lodash-es": "^4.17.21",
    "react-use": "^17.5.0"
  }
}
```

### Development Dependencies

```json
{
  "devDependencies": {
    // TypeScript
    "@types/node": "^20.11.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@types/sockjs-client": "^1.5.4",
    "@types/lodash-es": "^4.17.12",

    // Testing
    "vitest": "^1.3.0",
    "@testing-library/react": "^14.2.0",
    "@testing-library/jest-dom": "^6.4.0",
    "@testing-library/user-event": "^14.5.0",
    "@playwright/test": "^1.42.0",

    // Linting & Formatting
    "eslint": "^8.57.0",
    "eslint-config-next": "^14.2.0",
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0",
    "prettier": "^3.2.0",
    "prettier-plugin-tailwindcss": "^0.5.11",

    // Build Tools
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.35"
  }
}
```

---

## 🎨 Design System Integration

### Tailwind Configuration

**Design Tokens**:
```typescript
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        // Brand Colors
        primary: { /* ... */ },
        secondary: { /* ... */ },

        // Sport Colors
        futbol: '#10B981',
        baloncesto: '#F59E0B',
        baseball: '#3B82F6',
        // ...

        // Position Colors
        quarterback: '#8B5CF6',
        running_back: '#10B981',
        // ...

        // Semantic Colors
        success: '#10B981',
        warning: '#F59E0B',
        error: '#EF4444',
        info: '#3B82F6'
      },

      keyframes: {
        'score-pulse': { /* ... */ },
        'slide-in': { /* ... */ }
      }
    }
  }
}
```

### CVA Component Variants

**Type-safe variant system**:
```typescript
import { cva } from 'class-variance-authority'

const playerCardVariants = cva(
  'rounded-lg border p-4 transition-all',
  {
    variants: {
      position: {
        QB: 'border-purple-500 bg-purple-50',
        RB: 'border-green-500 bg-green-50',
        WR: 'border-blue-500 bg-blue-50'
      },
      state: {
        default: 'hover:shadow-md',
        dragging: 'opacity-50 rotate-2',
        locked: 'opacity-60 cursor-not-allowed'
      }
    },
    defaultVariants: {
      state: 'default'
    }
  }
)
```

---

## 🔄 Integration with Backend

### API Communication Pattern

```typescript
// Backend: Spring WebFlux REST
GET  /api/v1/leagues/{id}           → TanStack Query
POST /api/v1/trades                 → Mutation + Optimistic Update
WS   /topic/matches/{id}            → WebSocket Subscription

// Frontend Pattern
const { data: league } = useQuery(['league', id], fetchLeague)

const tradeMutation = useMutation({
  mutationFn: submitTrade,
  onMutate: async (newTrade) => {
    // Optimistic update
    await queryClient.cancelQueries(['roster'])
    const previous = queryClient.getQueryData(['roster'])
    queryClient.setQueryData(['roster'], (old) => ({
      ...old,
      players: applyTrade(old.players, newTrade)
    }))
    return { previous }
  },
  onError: (err, variables, context) => {
    // Rollback on error
    queryClient.setQueryData(['roster'], context.previous)
  }
})
```

### WebSocket Event Flow

```
Backend (Spring)          Frontend (React)
     |                          |
     | STOMP /topic/match/1     |
     |------------------------->|
     |   { type: "GOAL" }       |
     |                          |
     |                     invalidateQueries()
     |                          |
     |                     refetch scores
     |                          |
     |                     UI update
```

---

## 🚀 Migration Path to React Native

**Reusable Architecture**:

```typescript
// ✅ Reutilizable en React Native
- Business logic hooks (useRoster, useDraft)
- State management (Zustand stores)
- Type definitions (TypeScript types)
- Validation schemas (Zod)
- API client logic (TanStack Query)

// ❌ No reutilizable (Web-only)
- Next.js routing (usar React Navigation)
- Shadcn/ui componentes (recrear con React Native)
- Tailwind classes (usar NativeWind o StyleSheet)

// 🔄 Adaptable
- Drag & Drop (@dnd-kit → react-native-draggable)
- Animations (Framer Motion → Reanimated)
```

**Ejemplo de Hook Compartido**:

```typescript
// shared/hooks/useRoster.ts
// ✅ Funciona en Web y React Native
export const useRoster = (teamId: string) => {
  return useQuery({
    queryKey: ['roster', teamId],
    queryFn: () => fetchRoster(teamId)
  })
}

// Web: app/roster/page.tsx
import { useRoster } from '@/shared/hooks/useRoster'

// React Native: screens/RosterScreen.tsx
import { useRoster } from '@/shared/hooks/useRoster'
```

---

## 📊 Performance Targets

| Metric                         | Target  | Tool |
|--------------------------------|---------|------|
| First Contentful Paint (FCP)   | < 1.2s  | Lighthouse |
| Largest Contentful Paint (LCP) | < 2.5s  | Core Web Vitals |
| Time to Interactive (TTI)      | < 3.5s  | Lighthouse |
| Cumulative Layout Shift (CLS)  | < 0.1   | Core Web Vitals |
| First Input Delay (FID)        | < 100ms | Core Web Vitals |
| Bundle Size (Initial JS)       | < 200KB | webpack-bundle-analyzer |
| Lighthouse Score               | > 90    | Lighthouse CI |

**Optimizaciones**:
- Server Components para reducir client bundle
- Dynamic imports para code splitting
- Image optimization (Next.js Image)
- Edge caching (Vercel Edge)
- Font optimization (next/font)

---

## 🧪 Testing Strategy

```typescript
// Unit Tests (Vitest)
- Utility functions
- Custom hooks
- Validation schemas

// Component Tests (Testing Library)
- Component behavior
- User interactions
- Accessibility (a11y)

// Integration Tests (Testing Library)
- Feature flows
- Form submissions
- WebSocket integration

// E2E Tests (Playwright)
- Critical user journeys
- Draft flow
- Roster management
- Trade submission
```

---

## 🔒 Security Considerations

**Authentication Flow**:
```
1. Login → Backend JWT (access + refresh)
2. Store tokens: HttpOnly cookies (access) + localStorage (refresh)
3. Axios interceptor: Auto-refresh on 401
4. WebSocket: Send access token on STOMP connect
```

**Security Headers** (next.config.js):
```javascript
{
  headers: {
    'X-Frame-Options': 'DENY',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()'
  }
}
```

**Input Sanitization**:
- Zod schemas para validación
- DOMPurify para HTML user-generated (chat)
- CSP (Content Security Policy) en headers

---

## 📝 Development Workflow

### Project Structure

```
frontend/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Auth routes
│   ├── (dashboard)/       # Protected routes
│   ├── api/               # API routes (BFF)
│   └── layout.tsx         # Root layout
├── components/
│   ├── ui/                # Shadcn/ui components
│   ├── features/          # Feature components
│   │   ├── roster/
│   │   ├── draft/
│   │   └── scoring/
│   └── shared/            # Shared components
├── lib/
│   ├── api/               # API client
│   ├── hooks/             # Custom hooks
│   ├── schemas/           # Zod schemas
│   ├── stores/            # Zustand stores
│   ├── utils/             # Utilities
│   └── design-tokens/     # Design system
├── public/                # Static assets
└── types/                 # TypeScript types
```

### Scripts

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "format": "prettier --write .",
    "test": "vitest",
    "test:e2e": "playwright test",
    "type-check": "tsc --noEmit"
  }
}
```

---

## 🎯 Next Steps

1. ✅ **Stack Decision Approved** (este documento)
2. 🚧 **Setup Project**:
   - Initialize Next.js 14+ project
   - Configure Tailwind + Shadcn/ui
   - Setup TanStack Query + Zustand
   - Configure ESLint + Prettier
3. 🚧 **Implement Core Features**:
   - Authentication flow
   - WebSocket integration
   - Roster management
   - Draft room
4. 🚧 **Testing Setup**:
   - Vitest configuration
   - Playwright E2E
5. 🚧 **CI/CD Pipeline**:
   - GitHub Actions
   - Vercel deployment
   - Preview environments

---

## 📚 References

- [Next.js Documentation](https://nextjs.org/docs)
- [TanStack Query](https://tanstack.com/query/latest)
- [Shadcn/ui](https://ui.shadcn.com/)
- [DND Kit](https://dndkit.com/)
- [Zod](https://zod.dev/)
- [Spring WebSocket Guide](https://docs.spring.io/spring-framework/reference/web/websocket.html)

---