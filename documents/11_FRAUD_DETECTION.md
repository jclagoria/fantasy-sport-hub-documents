# Fraud Detection

> **ML-Powered Risk Scoring**: Detection of collusion, multi-accounting, and match-fixing

---

## 🎯 Fraud Types

### Detected Fraud Types

1. **Collusion**:
   - Suspicious trades between users for mutual benefit
   - Unbalanced trades between teams with the same owner
   - Coordination to manipulate waivers

2. **Multi-Accounting**:
   - Same user with multiple accounts in a league
   - Device fingerprinting and behavioral patterns

3. **Score Manipulation**:
   - Attempts to manipulate scores
   - Lineup changes after the deadline

4. **Betting Patterns**:
   - Suspicious betting patterns (if betting is implemented)
   - Insider information usage

---

## 🤖 ML-Based Detection

### Feature Engineering

```java
/**
 * Feature extraction for ML models.
 */
@Service
public class FraudFeatureExtractor {

    /**
     * Extracts features from a trade for collusion detection.
     */
    public TradeFeatures extractTradeFeatures(Trade trade) {
        return TradeFeatures.builder()
            // Player value features
            .playerValueDifference(calculateValueDifference(trade))
            .averagePointsDifference(calculateAvgPointsDiff(trade))
            .projectedPointsDifference(calculateProjectedDiff(trade))

            // User relationship features
            .userInteractionCount(getUserInteractionCount(
                trade.offeringUserId(),
                trade.receivingUserId()
            ))
            .previousTradesCount(getPreviousTradesCount(
                trade.offeringUserId(),
                trade.receivingUserId()
            ))
            .sameLeagueCount(getSameLeagueCount(
                trade.offeringUserId(),
                trade.receivingUserId()
            ))

            // Timing features
            .hoursSinceProposed(getHoursSinceProposed(trade))
            .isWeekendTrade(isWeekend(trade.proposedAt()))
            .isDeadlineProximity(isNearDeadline(trade))

            // League context features
            .standingsDifference(getStandingsDifference(trade))
            .isPlayoffContender(isPlayoffContender(trade.offeringUserId()))

            // Historical features
            .offeringUserRejectionRate(getUserRejectionRate(trade.offeringUserId()))
            .receivingUserAcceptanceRate(getUserAcceptanceRate(trade.receivingUserId()))

            .build();
    }

    /**
     * Extracts user features for multi-accounting detection.
     */
    public UserFeatures extractUserFeatures(User user, String ipAddress, String deviceFingerprint) {
        return UserFeatures.builder()
            // Device features
            .deviceFingerprint(deviceFingerprint)
            .ipAddress(ipAddress)
            .userAgent(extractUserAgent())

            // Behavioral features
            .avgSessionDuration(calculateAvgSessionDuration(user))
            .loginHoursDistribution(getLoginHoursDistribution(user))
            .actionVelocity(calculateActionVelocity(user))
            .typingSpeed(calculateTypingSpeed(user))

            // Account features
            .accountAge(getAccountAgeDays(user))
            .emailDomain(extractEmailDomain(user.email()))
            .phoneNumberPrefix(extractPhonePrefix(user.phoneNumber()))

            // League participation features
            .leaguesCount(getLeaguesCount(user))
            .averageLeagueSize(getAverageLeagueSize(user))
            .sharedLeaguesCount(getSharedLeaguesCount(user))

            .build();
    }

    private double calculateValueDifference(Trade trade) {
        var offeredValue = trade.offeredPlayers().stream()
            .mapToDouble(this::getPlayerMarketValue)
            .sum();

        var receivedValue = trade.requestedPlayers().stream()
            .mapToDouble(this::getPlayerMarketValue)
            .sum();

        return Math.abs(offeredValue - receivedValue) / Math.max(offeredValue, receivedValue);
    }

    private int getUserInteractionCount(UUID user1, UUID user2) {
        // Contar interacciones previas: trades, mensajes, waiver conflicts
        return 0;  // Implementation
    }

    private double getPlayerMarketValue(UUID playerId) {
        // Valor de mercado basado en puntos recientes + proyecciones
        return 0.0;  // Implementation
    }
}
```

### ML Models

```java
/**
 * Servicio de inferencia de modelos ML.
 */
@Service
public class FraudMLService {

    private final Model collusionModel;
    private final Model multiAccountModel;

    public FraudMLService() throws Exception {
        // Cargar modelos pre-entrenados (ONNX Runtime)
        this.collusionModel = loadModel("models/collusion-detector-v1.onnx");
        this.multiAccountModel = loadModel("models/multi-account-detector-v1.onnx");
    }

    /**
     * Predice probabilidad de colusión en un trade.
     */
    public Mono<FraudScore> predictCollusionRisk(TradeFeatures features) {
        return Mono.fromCallable(() -> {
            var inputTensor = featuresToTensor(features);
            var outputTensor = collusionModel.run(Map.of("input", inputTensor));

            var probability = extractProbability(outputTensor);
            var riskLevel = calculateRiskLevel(probability);

            return new FraudScore(
                FraudType.COLLUSION,
                probability,
                riskLevel,
                extractFeatureImportance(outputTensor)
            );
        });
    }

    /**
     * Predice probabilidad de multi-accounting.
     */
    public Mono<FraudScore> predictMultiAccountRisk(UserFeatures features) {
        return Mono.fromCallable(() -> {
            var inputTensor = featuresToTensor(features);
            var outputTensor = multiAccountModel.run(Map.of("input", inputTensor));

            var probability = extractProbability(outputTensor);
            var riskLevel = calculateRiskLevel(probability);

            return new FraudScore(
                FraudType.MULTI_ACCOUNT,
                probability,
                riskLevel,
                extractFeatureImportance(outputTensor)
            );
        });
    }

    private RiskLevel calculateRiskLevel(double probability) {
        if (probability >= 0.8) return RiskLevel.CRITICAL;
        if (probability >= 0.6) return RiskLevel.HIGH;
        if (probability >= 0.4) return RiskLevel.MEDIUM;
        return RiskLevel.LOW;
    }

    private Model loadModel(String path) throws Exception {
        var env = OrtEnvironment.getEnvironment();
        return env.createSession(path, new OrtSession.SessionOptions());
    }
}
```

---

## 📊 Rule-Based Detection

### Business Rules

```java
/**
 * Reglas de negocio para detección de fraude.
 */
@Service
public class FraudRuleEngine {

    /**
     * Evalúa reglas de colusión en trades.
     */
    public Mono<List<RuleViolation>> evaluateTradeRules(Trade trade) {
        var violations = new ArrayList<RuleViolation>();

        // Rule 1: Diferencia de valor extrema (>70%)
        var valueDiff = calculateValueDifference(trade);
        if (valueDiff > 0.7) {
            violations.add(new RuleViolation(
                "EXTREME_VALUE_DIFFERENCE",
                "Trade value difference exceeds 70%",
                Severity.HIGH,
                Map.of("difference", valueDiff)
            ));
        }

        // Rule 2: Trades frecuentes entre mismos usuarios
        var tradeCount = getPreviousTradesCount(
            trade.offeringUserId(),
            trade.receivingUserId()
        );
        if (tradeCount > 5) {
            violations.add(new RuleViolation(
                "FREQUENT_TRADES",
                "Users have traded more than 5 times",
                Severity.MEDIUM,
                Map.of("tradeCount", tradeCount)
            ));
        }

        // Rule 3: Trade poco antes de deadline
        var hoursToDeadline = getHoursToDeadline(trade);
        if (hoursToDeadline < 2) {
            violations.add(new RuleViolation(
                "DEADLINE_PROXIMITY",
                "Trade proposed within 2 hours of deadline",
                Severity.MEDIUM,
                Map.of("hoursToDeadline", hoursToDeadline)
            ));
        }

        // Rule 4: Uno de los usuarios está eliminado de playoffs
        if (isEliminatedFromPlayoffs(trade.offeringUserId())) {
            violations.add(new RuleViolation(
                "ELIMINATED_TEAM_TRADE",
                "Trading team is eliminated from playoffs",
                Severity.HIGH,
                Map.of("eliminatedUser", trade.offeringUserId())
            ));
        }

        return Mono.just(violations);
    }

    /**
     * Evalúa reglas de multi-accounting.
     */
    public Mono<List<RuleViolation>> evaluateMultiAccountRules(
        User user,
        String ipAddress,
        String deviceFingerprint
    ) {
        var violations = new ArrayList<RuleViolation>();

        // Rule 1: Mismo device fingerprint que otra cuenta
        return findUsersByDeviceFingerprint(deviceFingerprint)
            .collectList()
            .map(matchingUsers -> {
                if (matchingUsers.size() > 1) {
                    violations.add(new RuleViolation(
                        "SHARED_DEVICE",
                        "Device fingerprint matches multiple accounts",
                        Severity.HIGH,
                        Map.of("matchingUsers", matchingUsers.size())
                    ));
                }

                // Rule 2: Mismo IP address en corto periodo
                var recentIpUsers = getUsersWithSameIpRecently(ipAddress, Duration.ofHours(24));
                if (recentIpUsers.size() > 2) {
                    violations.add(new RuleViolation(
                        "SHARED_IP_ADDRESS",
                        "Multiple accounts from same IP within 24h",
                        Severity.MEDIUM,
                        Map.of("ipUsers", recentIpUsers.size())
                    ));
                }

                // Rule 3: Email domain gratuito + cuenta reciente
                if (isFreeEmailDomain(user.email()) && getAccountAgeDays(user) < 7) {
                    violations.add(new RuleViolation(
                        "NEW_FREE_EMAIL_ACCOUNT",
                        "New account with free email domain",
                        Severity.LOW,
                        Map.of("accountAgeDays", getAccountAgeDays(user))
                    ));
                }

                return violations;
            });
    }
}
```

---

## 🎯 Risk Scoring

### Aggregate Risk Score

```java
/**
 * Calcula score de riesgo agregado combinando ML + reglas.
 */
@Service
public class FraudScoringService {

    private final FraudMLService mlService;
    private final FraudRuleEngine ruleEngine;
    private final FraudScoreRepository scoreRepo;

    /**
     * Calcula risk score para un trade.
     */
    public Mono<AggregateRiskScore> calculateTradeRiskScore(Trade trade) {
        return Mono.zip(
            extractFeaturesAndPredict(trade),
            ruleEngine.evaluateTradeRules(trade)
        )
        .map(tuple -> {
            var mlScore = tuple.getT1();
            var ruleViolations = tuple.getT2();

            // Combinar ML score + rule violations
            var ruleScore = calculateRuleScore(ruleViolations);
            var finalScore = (mlScore.probability() * 0.7) + (ruleScore * 0.3);

            return new AggregateRiskScore(
                UUID.randomUUID(),
                FraudType.COLLUSION,
                finalScore,
                calculateRiskLevel(finalScore),
                mlScore,
                ruleViolations,
                Instant.now()
            );
        })
        .flatMap(score -> {
            // Guardar en DB para auditoría
            return scoreRepo.save(score);
        });
    }

    /**
     * Calcula risk score para un usuario.
     */
    public Mono<AggregateRiskScore> calculateUserRiskScore(
        User user,
        String ipAddress,
        String deviceFingerprint
    ) {
        return Mono.zip(
            extractFeaturesAndPredict(user, ipAddress, deviceFingerprint),
            ruleEngine.evaluateMultiAccountRules(user, ipAddress, deviceFingerprint)
        )
        .map(tuple -> {
            var mlScore = tuple.getT1();
            var ruleViolations = tuple.getT2();

            var ruleScore = calculateRuleScore(ruleViolations);
            var finalScore = (mlScore.probability() * 0.6) + (ruleScore * 0.4);

            return new AggregateRiskScore(
                UUID.randomUUID(),
                FraudType.MULTI_ACCOUNT,
                finalScore,
                calculateRiskLevel(finalScore),
                mlScore,
                ruleViolations,
                Instant.now()
            );
        });
    }

    private Mono<FraudScore> extractFeaturesAndPredict(Trade trade) {
        var features = featureExtractor.extractTradeFeatures(trade);
        return mlService.predictCollusionRisk(features);
    }

    private Mono<FraudScore> extractFeaturesAndPredict(
        User user,
        String ipAddress,
        String deviceFingerprint
    ) {
        var features = featureExtractor.extractUserFeatures(user, ipAddress, deviceFingerprint);
        return mlService.predictMultiAccountRisk(features);
    }

    /**
     * Convierte rule violations a score numérico.
     */
    private double calculateRuleScore(List<RuleViolation> violations) {
        return violations.stream()
            .mapToDouble(violation -> switch (violation.severity()) {
                case CRITICAL -> 1.0;
                case HIGH -> 0.7;
                case MEDIUM -> 0.4;
                case LOW -> 0.2;
            })
            .max()
            .orElse(0.0);
    }

    private RiskLevel calculateRiskLevel(double score) {
        if (score >= 0.8) return RiskLevel.CRITICAL;
        if (score >= 0.6) return RiskLevel.HIGH;
        if (score >= 0.4) return RiskLevel.MEDIUM;
        return RiskLevel.LOW;
    }
}
```

---

## 🚨 Automated Actions

### Risk-Based Actions

```java
/**
 * Acciones automáticas basadas en risk score.
 */
@Service
public class FraudActionService {

    private final NotificationService notificationService;
    private final TradeRepository tradeRepo;
    private final UserRepository userRepo;

    /**
     * Ejecuta acciones basadas en risk score de trade.
     */
    public Mono<Void> handleTradeRisk(Trade trade, AggregateRiskScore riskScore) {
        return Mono.defer(() -> {
            return switch (riskScore.riskLevel()) {
                case CRITICAL -> {
                    // Auto-reject trade + notificar comisionado
                    yield rejectTrade(trade, "Automatic rejection due to high fraud risk")
                        .then(notifyCommissioner(trade, riskScore))
                        .then(flagForManualReview(trade, riskScore));
                }
                case HIGH -> {
                    // Hold for commissioner approval
                    yield holdTradeForApproval(trade, riskScore)
                        .then(notifyCommissioner(trade, riskScore));
                }
                case MEDIUM -> {
                    // Flag + allow with notification
                    yield flagTrade(trade, riskScore)
                        .then(notifyUsers(trade, "Trade flagged for review"));
                }
                case LOW -> {
                    // Allow without action
                    yield Mono.empty();
                }
            };
        });
    }

    /**
     * Ejecuta acciones basadas en risk score de usuario.
     */
    public Mono<Void> handleUserRisk(User user, AggregateRiskScore riskScore) {
        return Mono.defer(() -> {
            return switch (riskScore.riskLevel()) {
                case CRITICAL -> {
                    // Suspend account + require verification
                    yield suspendAccount(user, "Suspected multi-accounting")
                        .then(requireIdentityVerification(user))
                        .then(notifyAdmins(user, riskScore));
                }
                case HIGH -> {
                    // Require MFA + limit actions
                    yield requireMFA(user)
                        .then(limitActions(user, Duration.ofDays(7)))
                        .then(notifyAdmins(user, riskScore));
                }
                case MEDIUM -> {
                    // Increased monitoring
                    yield enableEnhancedMonitoring(user, Duration.ofDays(30))
                        .then(logSecurityEvent(user, riskScore));
                }
                case LOW -> {
                    // Normal operation
                    yield Mono.empty();
                }
            };
        });
    }

    private Mono<Void> rejectTrade(Trade trade, String reason) {
        trade.setStatus(TradeStatus.REJECTED);
        trade.setRejectionReason(reason);
        return tradeRepo.save(trade).then();
    }

    private Mono<Void> holdTradeForApproval(Trade trade, AggregateRiskScore riskScore) {
        trade.setStatus(TradeStatus.PENDING_COMMISSIONER_APPROVAL);
        trade.setFraudScore(riskScore.finalScore());
        return tradeRepo.save(trade).then();
    }

    private Mono<Void> suspendAccount(User user, String reason) {
        user.setAccountStatus(AccountStatus.SUSPENDED);
        user.setSuspensionReason(reason);
        user.setSuspendedAt(Instant.now());
        return userRepo.save(user).then();
    }

    private Mono<Void> notifyCommissioner(Trade trade, AggregateRiskScore riskScore) {
        return notificationService.sendFraudAlert(
            trade.leagueId(),
            "High-risk trade detected",
            Map.of(
                "tradeId", trade.id(),
                "riskScore", riskScore.finalScore(),
                "riskLevel", riskScore.riskLevel(),
                "violations", riskScore.ruleViolations()
            )
        );
    }
}
```

---

## 📈 Model Training Pipeline

### Training Data Collection

```java
/**
 * Recolección de datos para entrenamiento de modelos.
 */
@Service
public class TrainingDataCollector {

    private final TradeRepository tradeRepo;
    private final FraudLabelRepository labelRepo;

    /**
     * Genera dataset de trades etiquetados.
     */
    public Mono<Dataset> generateTradeDataset() {
        return tradeRepo.findAll()
            .flatMap(trade -> {
                return Mono.zip(
                    Mono.just(trade),
                    featureExtractor.extractTradeFeatures(trade),
                    labelRepo.findByTradeId(trade.id())
                );
            })
            .collectList()
            .map(records -> {
                var features = records.stream()
                    .map(Tuple3::getT2)
                    .toList();

                var labels = records.stream()
                    .map(tuple -> tuple.getT3().isFraudulent() ? 1 : 0)
                    .toList();

                return new Dataset(features, labels);
            });
    }

    /**
     * Exporta dataset a formato CSV para entrenamiento offline.
     */
    public Mono<Path> exportDatasetToCSV() {
        return generateTradeDataset()
            .map(dataset -> {
                var csvPath = Path.of("/tmp/fraud-training-data.csv");
                // Write CSV
                return csvPath;
            });
    }
}
```

### Model Retraining

```python
# Offline model training script (Python)
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import onnx
from skl2onnx import convert_sklearn

def train_collusion_model():
    # Load data
    df = pd.read_csv('fraud-training-data.csv')

    # Split features and labels
    X = df.drop(['is_fraudulent'], axis=1)
    y = df['is_fraudulent']

    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    # Train model
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=10,
        random_state=42
    )
    model.fit(X_train, y_train)

    # Evaluate
    accuracy = model.score(X_test, y_test)
    print(f"Model accuracy: {accuracy}")

    # Convert to ONNX
    onnx_model = convert_sklearn(
        model,
        initial_types=[('input', FloatTensorType([None, X.shape[1]]))],
    )

    # Save ONNX model
    with open('collusion-detector-v2.onnx', 'wb') as f:
        f.write(onnx_model.SerializeToString())

if __name__ == '__main__':
    train_collusion_model()
```

---

## 🧪 Testing Fraud Detection

### Unit Tests

```java
@SpringBootTest
class FraudScoringServiceTest {

    @Autowired
    private FraudScoringService scoringService;

    @Test
    void shouldDetectObviousCollusion() {
        // Setup: Trade extremadamente desequilibrado
        var trade = Trade.builder()
            .id(UUID.randomUUID())
            .offeredPlayers(List.of(TOP_PLAYER_ID))  // Jugador top
            .requestedPlayers(List.of(BENCH_PLAYER_ID))  // Jugador de banca
            .build();

        var riskScore = scoringService.calculateTradeRiskScore(trade).block();

        assertThat(riskScore.riskLevel()).isIn(RiskLevel.HIGH, RiskLevel.CRITICAL);
        assertThat(riskScore.finalScore()).isGreaterThan(0.6);
    }

    @Test
    void shouldDetectMultiAccounting() {
        var user = createTestUser();
        var deviceFingerprint = "existing-device-123";

        // Simular otro usuario con mismo device
        createAnotherUserWithDevice(deviceFingerprint);

        var riskScore = scoringService.calculateUserRiskScore(
            user,
            "192.168.1.1",
            deviceFingerprint
        ).block();

        assertThat(riskScore.riskLevel()).isGreaterThanOrEqualTo(RiskLevel.MEDIUM);
    }
}
```

---
