# Architecture Decision Records (ADRs)

> Record of critical architectural decisions with context, evaluated options, and justification.

---

## 📋 ADR Index

| ID                  | Title                                | Status | Date |
|---------------------|--------------------------------------|--------|------|
| [ADR-001](#adr-001) | Plugin Architecture for Multi-Sport  | ✅ Accepted | 2025-11-08 |
| [ADR-002](#adr-002) | Hybrid Event Sourcing (CRUD + ES)    | ✅ Accepted | 2025-11-08 |
| [ADR-003](#adr-003) | Two-Phase Scoring (Live + Post-Match)| ✅ Accepted | 2025-11-08 |
| [ADR-004](#adr-004) | Multi-Provider with Automatic Fallback| ✅ Accepted | 2025-11-08 |
| [ADR-005](#adr-005) | Java 21 with Reactive Programming    | ✅ Accepted | 2025-11-08 |
| [ADR-006](#adr-006) | Kafka as Main Event Bus              | ✅ Accepted | 2025-11-08 |
| [ADR-007](#adr-007) | MongoDB for Read Models (CQRS)       | ✅ Accepted | 2025-11-08 |
| [ADR-008](#adr-008) | JWT with Token Rotation              | ✅ Accepted | 2025-11-08 |
| [ADR-009](#adr-009) | ML-Based Fraud Detection             | ✅ Accepted | 2025-11-08 |
| [ADR-010](#adr-010) | Kubernetes with HPA for Scaling      | ✅ Accepted | 2025-11-08 |
| [ADR-011](#adr-011) | Frontend Stack: Next.js 14 + React 18| ✅ Accepted | 2025-11-09 |

---

## ADR-001: Multi-Sport Plugin Architecture

**Status**: ✅ Accepted
**Date**: 2025-11-08
**Authors**: Architecture Team

### Context

The system must support 5+ sports simultaneously (soccer, basketball, baseball, tennis, hockey). Each sport has:
- Different positions
- Unique statistics
- Specific scoring rules
- Distinct schedules

### Decision

Implement **Plugin Architecture** with a sport-agnostic core and configurable plugins per sport.

**Design**:
```java
// Generic core
public interface SportScoringConfig {
    String sportId();
    List<LiveRule> liveRules();
    List<PostMatchRule> postMatchRules();
}

// Plugin-specific
@Component
public class SoccerScoringConfig implements SportScoringConfig {
    // Soccer-specific implementation
}
```

### Considered Alternatives

#### Option A: Inheritance (Sport Base Class)

```java
abstract class Sport {
    abstract calculateScore();
}
class Soccer extends Sport { ... }
```

**Pros**: Simple, object-oriented
**Cons**: Rigid, difficult to add sports without modifying core

#### Option B: Massive If/Else

```java
if (sport == "soccer") { ... }
else if (sport == "basketball") { ... }
```

**Pros**: Direct
**Cons**: Not scalable, violates Open/Closed Principle

#### Option C: Plugin Architecture ✅ **CHOSEN**

**Pros**:
- Extensibility without modifying core
- Isolation between sports
- Easy testing per sport
- Dynamic configuration
- Isolation between sports
- Easy testing per sport
- Dynamic configuration

**Cons**:
- More complex initially
- Requires Registry pattern

### Consequences

**Positive**:
- Add new sport = new plugin, without touching core
- Independent testing per sport
- Externalized configuration

**Negative**:
- Abstraction overhead
- Need for SportRegistry

**Mitigations**:
- Clearly document plugin contract
- Provide example plugin (SoccerPlugin)

---

## ADR-002: Hybrid Event Sourcing (CRUD + ES)

**Status**: ✅ Accepted
**Date**: 2025-11-08

### Context

We need:
- Complete audit trail of match events
- Match replay capability
- Fast queries for users/teams/leagues
- We don't want complexity in the ENTIRE system

### Decision

**Event Sourcing ONLY for match events**, traditional CRUD for users/teams/leagues.

**Architecture**:

```
Users/Teams/Leagues → PostgreSQL (ACID transactions)
Match Events/Scoring → EventStoreDB + Kafka (Event Sourcing)
Read Models → MongoDB (CQRS projections)
```

### Considered Alternatives

#### Option A: Event Sourcing for Everything
**Pros**: Consistency
**Cons**: Overkill for simple CRUD, eventual consistency in users

#### Option B: No Event Sourcing (only traditional DB)
**Pros**: Simplicity
**Cons**: No audit trail, no replay, difficult debugging

#### Option C: Hybrid ✅ **CHOSEN**
**Pros**:
- Event Sourcing where it adds value (matches)
- CRUD where it is sufficient (users)
- Best of both worlds

**Cons**:
- Two paradigms in one system

### Consequences

**Positive**:
- Complete scoring audit trail
- Match replay possible
- Fast user/team queries
- Lower complexity than full ES

**Negative**:
- Synchronization between ES and CRUD
- Need for projections

**Mitigations**:
- Use patterns like Transactional Outbox
- Eventually consistent projections

---

## ADR-003: Scoring en Dos Fases (Live + Post-Match)

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

Reglas de scoring complejas como "hat-trick en playoff ganado = +50 puntos" 
requieren contexto completo del partido (resultado final, fase del torneo), 
pero usuarios quieren ver puntos en tiempo real.

### Decisión

**Dos fases de cálculo**:

**Fase 1: Live Scoring** (durante el partido)
- Reglas simples: GOL=10, ASISTENCIA=5
- Actualización en tiempo real vía WebSocket
- No requiere contexto del resultado

**Fase 2: Post-Match Bonuses** (al finalizar)
- Reglas complejas con contexto completo
- Bonos aplicados después
- Notificación de bonos ganados

### Opciones Consideradas

#### Opción A: Todo al Final del Partido
**Pros**: Simplicidad, cálculo completo
**Contras**: Sin experiencia live, usuarios no ven puntos durante partido

#### Opción B: Todo en Tiempo Real ✅ Parcial
**Pros**: Mejor UX
**Contras**: Imposible calcular bonos complejos sin resultado final

#### Opción C: Dos Fases ✅ **ELEGIDA**
**Pros**:
- UX live para reglas simples
- Precisión para reglas complejas
- Balance perfecto

**Contras**:
- Dos engines de scoring
- Usuarios ven puntos cambiar después del partido

### Consecuencias

**Positivas**:
- Mejor experiencia de usuario
- Flexibilidad para reglas complejas
- Arquitectura clara

**Mitigaciones**:
- Comunicar claramente: "Bonos post-partido calculándose"
- UI que diferencia puntos live vs bonos

---

## ADR-004: Multi-Provider con Fallback Automático

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

Con 5 deportes, necesitamos múltiples APIs:
- API-Football (fútbol)
- SportsData.io (múltiples deportes, caro)
- MLB Stats API (baseball, gratis)
- NHL API (hockey)

APIs fallan, tienen rate limits, disponibilidad variable.

### Decisión

**Multi-provider architecture con fallback automático**:

```java
ProviderRegistry
    .register("FUTBOL", apiFootball, PRIMARY)
    .register("FUTBOL", sportsData, FALLBACK)
    .register("BALONCESTO", sportsData, PRIMARY)
```

**Smart Router**:
- Health scoring de providers
- Fallback automático si primary falla
- Circuit Breaker por provider

### Opciones Consideradas

#### Opción A: Single Provider por Deporte
**Pros**: Simplicidad
**Contras**: Sin resiliencia, downtime = servicio caído

#### Opción B: Manual Failover
**Pros**: Control total
**Contras**: Requiere intervención humana, downtime largo

#### Opción C: Multi-Provider Auto-Fallback ✅ **ELEGIDA**
**Pros**:
- Alta disponibilidad
- Recuperación automática
- Optimización de costos (usa gratis primero)

**Contras**:
- Complejidad en router
- Riesgo de inconsistencia entre providers

### Consecuencias

**Positivas**:
- 99.9% uptime posible
- Recuperación en segundos, no minutos

**Negativas**:
- Necesidad de deduplicación de eventos
- Monitoreo de múltiples providers

**Mitigaciones**:
- DataNormalizationService para deduplicar
- Health monitoring con métricas

---

## ADR-005: Java 21 con Programación Reactiva

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

Sistema debe manejar:
- 100K usuarios concurrentes
- 10K eventos/segundo
- WebSocket streaming
- Backpressure con APIs externas

### Decisión

**Java 21 + Project Reactor (Spring WebFlux)**

**Características usadas**:
- Virtual Threads (Project Loom)
- Pattern Matching
- Records
- Reactive Streams (Reactor)

### Opciones Consideradas

#### Opción A: Java 17 + Blocking I/O
**Pros**: Más simple, familiar
**Contras**: No escala a 100K usuarios, thread-per-request costoso

#### Opción B: Node.js/Go
**Pros**: Async nativo
**Contras**: Equipo tiene experiencia Java, ecosistema diferente

#### Opción C: Java 21 Reactive ✅ **ELEGIDA**
**Pros**:
- Escalabilidad no-bloqueante
- Virtual Threads para código bloqueante ocasional
- Ecosistema Spring maduro
- Performance excelente

**Contras**:
- Curva de aprendizaje reactiva
- Debugging más complejo

### Consecuencias

**Positivas**:
- Maneja 100K+ usuarios con recursos razonables
- Backpressure automático

**Negativas**:
- Equipo debe aprender programación reactiva
- Testing diferente (StepVerifier)

**Mitigaciones**:
- Training en reactive programming
- Code reviews enfocados en patterns reactivos

---

## ADR-006: Kafka como Event Bus Principal

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

Sistema event-driven con:
- Event sourcing para matches
- Proyecciones CQRS
- Integración con múltiples APIs
- Necesidad de replay

### Decisión

**Kafka como event bus principal** con topics específicos:
- `raw-sports-events`: Eventos de APIs externas
- `normalized-match-events`: Eventos deduplicados
- `scoring-events`: Puntuaciones calculadas
- `system-events`: Eventos de sistema

### Opciones Consideradas

#### Opción A: RabbitMQ
**Pros**: Más simple, bueno para queues
**Contras**: No diseñado para event sourcing, sin replay fácil

#### Opción B: AWS EventBridge
**Pros**: Serverless, escalado automático
**Contras**: Vendor lock-in, costos variables

#### Opción C: Kafka ✅ **ELEGIDA**
**Pros**:
- Log distribuido (event sourcing natural)
- Replay fácil
- High throughput (10K+ eventos/sec)
- Kafka Streams para procesamiento
- Partitioning para escalabilidad

**Contras**:
- Más complejo de operar
- Overhead de Zookeeper/KRaft

### Consecuencias

**Positivas**:
- Event sourcing natural
- Escalabilidad horizontal
- Replay de eventos

**Negativas**:
- Requires Kafka expertise
- Infrastructure overhead

**Mitigaciones**:
- Usar Strimzi operator en Kubernetes
- Monitoring completo con Prometheus

---

## ADR-007: MongoDB para Read Models (CQRS)

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

CQRS read models necesitan:
- Queries rápidas de leaderboards
- Documentos denormalizados
- Agregaciones complejas
- Schema flexible

### Decisión

**MongoDB para todas las proyecciones CQRS**:
- `match_projections`: Estado actual de partidos
- `weekly_team_scores`: Puntuaciones por semana
- `player_statistics`: Stats agregadas

### Opciones Consideradas

#### Opción A: PostgreSQL para Todo
**Pros**: Una sola tecnología
**Contras**: Queries complejas lentas, schema rígido

#### Opción B: Elasticsearch
**Pros**: Full-text search, agregaciones
**Contras**: Overkill, más complejo

#### Opción C: MongoDB ✅ **ELEGIDA**
**Pros**:
- Documentos denormalizados = queries rápidas
- Aggregation pipeline potente
- Schema flexible para deportes diferentes
- Replica sets para HA

**Contras**:
- Otra tecnología en el stack
- Eventual consistency

### Consecuencias

**Positivas**:
- Leaderboards < 200ms
- Queries flexibles

**Negativas**:
- Dos databases (Postgres + Mongo)

**Mitigaciones**:
- Rebuilder para reconstruir proyecciones desde events

---

## ADR-008: JWT con Token Rotation

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

Autenticación stateless para:
- API REST
- WebSocket
- Mobile apps

Necesidad de seguridad sin session storage.

### Decisión

**JWT con rotation**:
- Access Token: 15 minutos TTL
- Refresh Token: 7 días TTL
- Refresh rotation: nuevo par de tokens cada refresh

### Opciones Consideradas

#### Opción A: Session-based (cookies)
**Pros**: Revocación fácil
**Contras**: Stateful, no funciona bien con mobile

#### Opción B: JWT sin Rotation
**Pros**: Simple
**Contras**: Si token se compromete, válido hasta expiración

#### Opción C: JWT con Rotation ✅ **ELEGIDA**
**Pros**:
- Stateless (escalable)
- Rotation reduce ventana de compromiso
- Revocación posible vía refresh token blacklist

**Contras**:
- Más complejo
- Refresh token storage (Redis)

### Consecuencias

**Positivas**:
- Escalable horizontalmente
- Seguro con rotation

**Negativas**:
- Refresh logic adicional

**Mitigaciones**:
- Cliente auto-refresh transparente
- Clear error messages para token expirado

---

## ADR-009: ML-Based Fraud Detection

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

Fantasy sports vulnerable a:
- Collusion (usuarios intercambian jugadores injustamente)
- Multi-accounting (una persona con varias cuentas)
- Commissioner abuse

### Decisión

**Sistema ML de detección con features**:
- Transaction imbalance score
- User behavior metrics
- Timing features
- Network features (graph analysis)

**Modelo**: Random Forest Classifier

**Acción por nivel de riesgo**:
- LOW: Auto-approve
- MEDIUM: Flag para comisionado
- HIGH: Block + require approval
- CRITICAL: Suspend accounts

### Opciones Consideradas

#### Opción A: Rules-based Detection
**Pros**: Predecible, explicable
**Contras**: Fácil de evadir, inflexible

#### Opción B: Manual Review de Todo
**Pros**: Humano decide
**Contras**: No escala, lento

#### Opción C: ML-based ✅ **ELEGIDA**
**Pros**:
- Detecta patrones complejos
- Aprende de nuevos casos
- Escalable

**Contras**:
- Black box (difícil explicar)
- Requiere training data
- Falsos positivos

### Consecuencias

**Positivas**:
- Detección proactiva de fraude
- Reduce carga de comisionados

**Negativas**:
- Necesita dataset de training
- Falsos positivos molestan usuarios

**Mitigaciones**:
- Start con umbral bajo (menos falsos positivos)
- Feedback loop para mejorar modelo
- Explicabilidad con SHAP values

---

## ADR-010: Kubernetes con HPA para Scaling

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-08

### Contexto

Sistema debe escalar de 10K usuarios (off-season) a 100K (match days) dinámicamente.

### Decisión

**Kubernetes con Horizontal Pod Autoscaler**:
- Min replicas: 10
- Max replicas: 50
- Scale on: CPU 70%, Memory 80%, custom metrics (req/sec)

**StatefulSets para**:
- Kafka
- PostgreSQL
- MongoDB

**Deployments para**:
- API (stateless)
- Event Processor (stateless con consumer groups)

### Opciones Consideradas

#### Opción A: VMs con Auto Scaling Group
**Pros**: Más simple
**Contras**: Escalado lento (minutos), overhead de VM

#### Opción B: Serverless (AWS Lambda)
**Pros**: Escalado instantáneo
**Contras**: Cold starts, vendor lock-in, no WebSocket

#### Opción C: Kubernetes HPA ✅ **ELEGIDA**
**Pros**:
- Escalado en segundos
- Control total
- Multi-cloud portable
- WebSocket support

**Contras**:
- Complejidad operacional
- Requiere K8s expertise

### Consecuencias

**Positivas**:
- Escalado automático según demanda
- Costos optimizados (escala down cuando no se usa)

**Negativas**:
- Requiere equipo con K8s knowledge
- Infraestructura más compleja

**Mitigaciones**:
- Managed Kubernetes (EKS, GKE, AKS)
- Helm charts para deployment repetible
- Comprehensive monitoring

---

## 📝 Formato de ADR

Para crear nuevos ADRs, usar este template:

```markdown
## ADR-XXX: [Título de la Decisión]

**Estado**: 🚧 Propuesta | ✅ Aceptada | ❌ Rechazada | ⚠️ Deprecada
**Fecha**: YYYY-MM-DD
**Autores**: [Nombres]

### Contexto
[Por qué necesitamos tomar esta decisión? Qué problema resuelve?]

### Decisión
[Qué decidimos hacer? Cómo funciona?]

### Opciones Consideradas

#### Opción A: [Nombre]
**Pros**: [...]
**Contras**: [...]

#### Opción B: [Nombre] ✅ ELEGIDA
**Pros**: [...]
**Contras**: [...]

### Consecuencias

**Positivas**: [...]
**Negativas**: [...]
**Mitigaciones**: [...]
```

---

## ADR-011: Frontend Stack - Next.js 14 + React 18

**Estado**: ✅ Aceptada
**Fecha**: 2025-11-09
**Autores**: Architecture Team

### Contexto

Necesitamos stack tecnológico para frontend que:
- Soporte 100K+ usuarios concurrentes
- Experiencia real-time (scoring live, draft, chat)
- Multi-dispositivo (web responsive ahora, nativas después)
- Integración con Spring Boot WebFlux backend
- SEO para ligas públicas
- Performance óptimo (dashboards complejos)

### Decisión

**Stack Frontend Completo**:

**Framework & Core**:
- Next.js 14+ (App Router)
- React 18+ (Server Components)
- TypeScript 5+

**State Management**:
- TanStack Query v5 → Server state
- Zustand → Client state

**Real-time**:
- SockJS + STOMP → WebSocket (Spring compatible)

**UI & Styling**:
- Shadcn/ui (Radix + Tailwind)
- CVA para variants
- Framer Motion para animations

**Interactions**:
- @dnd-kit → Drag & drop
- React Hook Form + Zod → Forms & validation

**Data Viz**:
- Recharts → Charts

### Opciones Consideradas

#### Framework

**Opción A: Remix**
**Pros**: Excelente manejo de datos, nested routing
**Contras**: Menor ecosistema real-time, sin Edge Runtime

**Opción B: SvelteKit**
**Pros**: Bundle pequeño, performance
**Contras**: Menor adopción, difícil migración a React Native

**Opción C: Next.js 14+ ✅ ELEGIDA**
**Pros**:
- SSR + RSC mejora SEO y performance
- Streaming compatible con WebFlux
- Edge Runtime para CDN global
- Path claro a React Native
- Ecosistema maduro

**Contras**:
- Curva aprendizaje App Router
- Complejidad Server/Client Components

#### State Management

**Opción A: Redux Toolkit**
**Pros**: Patrón conocido, DevTools
**Contras**: Boilerplate excesivo, overkill

**Opción B: TanStack Query + Zustand ✅ ELEGIDA**
**Pros**:
- TanStack Query: caché inteligente, optimistic updates
- Zustand: ligero (<1KB), simple API
- Separación clara server/client state

**Contras**: Dos librerías (complejidad conceptual)

#### Real-time

**Opción A: Socket.io**
**Pros**: Popular en Node.js
**Contras**: No compatible nativo con Spring, requiere proxy

**Opción B: SockJS + STOMP ✅ ELEGIDA**
**Pros**:
- Compatibilidad nativa Spring WebSocket
- Fallback automático (WebSocket → polling)
- STOMP protocol para pub/sub

**Contras**: Overhead vs WebSocket nativo

#### UI Components

**Opción A: Material-UI**
**Pros**: Completo, maduro
**Contras**: Bundle grande (>300KB), difícil customizar

**Opción B: Shadcn/ui ✅ ELEGIDA**
**Pros**:
- No es librería, es código copiado (control total)
- Radix = accesibilidad garantizada
- Tailwind = zero runtime CSS
- Headless pattern = reutilizable en React Native

**Contras**: Código vive en proyecto (mantenimiento manual)

#### Drag & Drop

**Opción A: react-beautiful-dnd**
**Pros**: UX excelente
**Contras**: Deprecado, no React 18+

**Opción B: @dnd-kit ✅ ELEGIDA**
**Pros**:
- Touch-friendly (móvil)
- Accesibilidad built-in
- Performance con virtualización

**Contras**: Menos maduro

### Consecuencias

**Positivas**:
- Performance óptimo (SSR + Edge + caché)
- Escalabilidad para 100K+ usuarios
- Type safety end-to-end (TypeScript + Zod)
- Real-time nativo con Spring
- Path claro a React Native (reutilizar hooks, lógica)
- Accesibilidad garantizada (Radix)

**Negativas**:
- Equipo debe aprender:
  - App Router (Server/Client Components)
  - Programación reactiva (TanStack Query)
  - Zod schemas
- Dos paradigmas state (server/client)
- Debugging más complejo (WebSocket + optimistic updates)

**Mitigaciones**:
- Training en Next.js 14 App Router
- Documentar patterns de Server/Client Components
- Code examples en docs del proyecto
- Linting rules para evitar errores comunes
- Monitoring de WebSocket connections

**Detalles Técnicos**: Ver [23_FRONTEND_STACK.md](./23_FRONTEND_STACK.md) para documentación completa.

---
