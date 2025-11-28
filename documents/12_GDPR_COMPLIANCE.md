# GDPR & CCPA Compliance

> **Data Subject Rights + Privacy by Design**: Full compliance with GDPR/CCPA

---

## 🎯 Regulatory Requirements

### GDPR (General Data Protection Regulation)

**Scope**: Users in the European Union
**Key Principles**:
- Lawfulness, fairness, transparency
- Purpose limitation
- Data minimization
- Accuracy
- Storage limitation
- Integrity and confidentiality
- Accountability

### CCPA (California Consumer Privacy Act)

**Scope**: Users in California, USA
**Consumer Rights**:
- Right to know
- Right to delete
- Right to opt-out of sale
- Right to non-discrimination

---

## 📋 Data Subject Rights

### Right to Access (GDPR Art. 15)

```java
/**
 * Service to export all user data.
 */
@Service
public class DataExportService {

    private final UserRepository userRepo;
    private final TeamRepository teamRepo;
    private final TradeRepository tradeRepo;
    private final AuditLogRepository auditRepo;

    /**
     * Generates a complete export of personal data (JSON format).
     */
    public Mono<PersonalDataExport> exportUserData(UUID userId) {
        return Mono.zip(
            userRepo.findById(userId),
            teamRepo.findByOwnerId(userId).collectList(),
            tradeRepo.findByUserId(userId).collectList(),
            auditRepo.findByUserId(userId).collectList()
        )
        .map(tuple -> {
            var user = tuple.getT1();
            var teams = tuple.getT2();
            var trades = tuple.getT3();
            var auditLogs = tuple.getT4();

            return PersonalDataExport.builder()
                .exportedAt(Instant.now())
                .user(sanitizeUser(user))
                .teams(sanitizeTeams(teams))
                .trades(sanitizeTrades(trades))
                .activityLog(sanitizeAuditLogs(auditLogs))
                .build();
        });
    }

    /**
     * Genera export en formato portable (JSON o CSV).
     */
    public Mono<byte[]> exportAsJSON(UUID userId) {
        return exportUserData(userId)
            .map(export -> {
                try {
                    return objectMapper.writeValueAsBytes(export);
                } catch (JsonProcessingException e) {
                    throw new DataExportException("JSON export failed", e);
                }
            });
    }

    /**
     * Envía export por email al usuario.
     */
    public Mono<Void> sendDataExportEmail(UUID userId) {
        return exportAsJSON(userId)
            .flatMap(jsonData -> {
                return userRepo.findById(userId)
                    .flatMap(user ->
                        emailService.sendEmail(
                            user.email(),
                            "Your Personal Data Export",
                            "Please find attached your personal data export.",
                            Map.of("data-export.json", jsonData)
                        )
                    );
            });
    }

    private UserData sanitizeUser(User user) {
        return new UserData(
            user.id(),
            user.email(),
            user.createdAt(),
            user.lastLoginAt(),
            user.accountStatus()
        );
    }
}
```

### Right to Erasure (GDPR Art. 17)

```java
/**
 * Servicio para eliminación de datos personales ("Right to be Forgotten").
 */
@Service
public class DataErasureService {

    private final UserRepository userRepo;
    private final TeamRepository teamRepo;
    private final TradeRepository tradeRepo;
    private final AuditLogRepository auditRepo;
    private final EventStoreDB eventStore;

    /**
     * Elimina completamente los datos de un usuario.
     *
     * NOTA: Algunos datos pueden retenerse por obligaciones legales:
     * - Audit logs (6 años por regulaciones fiscales)
     * - Fraud detection data (hasta resolución de disputas)
     */
    public Mono<ErasureResult> eraseUserData(UUID userId, ErasureReason reason) {
        return Mono.defer(() -> {
            log.info("Starting data erasure for user {}, reason: {}", userId, reason);

            return Mono.zip(
                anonymizeUser(userId),
                deleteTeams(userId),
                anonymizeTrades(userId),
                pseudonymizeAuditLogs(userId),
                deleteEventStoreData(userId)
            )
            .map(tuple -> new ErasureResult(
                userId,
                Instant.now(),
                reason,
                Map.of(
                    "userAnonymized", tuple.getT1(),
                    "teamsDeleted", tuple.getT2(),
                    "tradesAnonymized", tuple.getT3(),
                    "auditLogsPseudonymized", tuple.getT4(),
                    "eventsDeleted", tuple.getT5()
                )
            ))
            .doOnSuccess(result -> {
                log.info("Data erasure completed for user {}: {}", userId, result);
                auditErasure(userId, reason, result);
            });
        });
    }

    /**
     * Anonimiza usuario (mantiene registro pero sin datos personales).
     */
    private Mono<Boolean> anonymizeUser(UUID userId) {
        return userRepo.findById(userId)
            .flatMap(user -> {
                user.setEmail("deleted-" + userId + "@anonymized.local");
                user.setPasswordHash("DELETED");
                user.setPhoneNumber(null);
                user.setMfaSecret(null);
                user.setAccountStatus(AccountStatus.DELETED);
                user.setDeletionDate(Instant.now());

                return userRepo.save(user);
            })
            .thenReturn(true);
    }

    /**
     * Elimina equipos del usuario.
     */
    private Mono<Integer> deleteTeams(UUID userId) {
        return teamRepo.findByOwnerId(userId)
            .flatMap(teamRepo::delete)
            .count()
            .map(Long::intValue);
    }

    /**
     * Anonimiza trades (mantiene por integridad referencial).
     */
    private Mono<Integer> anonymizeTrades(UUID userId) {
        return tradeRepo.findByUserId(userId)
            .flatMap(trade -> {
                // Reemplazar userId con UUID anonimizado
                var anonymizedId = UUID.nameUUIDFromBytes(
                    ("ANONYMIZED-" + userId).getBytes()
                );

                if (trade.offeringUserId().equals(userId)) {
                    trade.setOfferingUserId(anonymizedId);
                }
                if (trade.receivingUserId().equals(userId)) {
                    trade.setReceivingUserId(anonymizedId);
                }

                return tradeRepo.save(trade);
            })
            .count()
            .map(Long::intValue);
    }

    /**
     * Pseudonimiza audit logs (requeridos por ley, pero sin PII).
     */
    private Mono<Integer> pseudonymizeAuditLogs(UUID userId) {
        var pseudonym = UUID.nameUUIDFromBytes(
            ("PSEUDONYM-" + userId).getBytes()
        );

        return auditRepo.findByUserId(userId)
            .flatMap(log -> {
                log.setUserId(pseudonym);
                log.setIpAddress(hashIP(log.ipAddress()));
                log.setUserAgent("REDACTED");
                return auditRepo.save(log);
            })
            .count()
            .map(Long::intValue);
    }

    /**
     * Elimina eventos de EventStoreDB (soft delete).
     */
    private Mono<Integer> deleteEventStoreData(UUID userId) {
        // EventStoreDB no soporta delete físico
        // Escribir evento de tombstone
        return Mono.fromCallable(() -> {
            var tombstone = new UserDataDeleted(
                UUID.randomUUID(),
                userId,
                Instant.now(),
                "GDPR erasure request"
            );

            eventStore.appendEvent("user-" + userId, tombstone);
            return 1;
        });
    }

    private void auditErasure(UUID userId, ErasureReason reason, ErasureResult result) {
        auditRepo.save(new AuditLog(
            UUID.randomUUID(),
            userId,
            "DATA_ERASURE",
            Instant.now(),
            null,
            null,
            Map.of(
                "reason", reason,
                "result", result
            )
        ));
    }

    private String hashIP(String ipAddress) {
        try {
            var md = MessageDigest.getInstance("SHA-256");
            var hash = md.digest(ipAddress.getBytes());
            return Base64.getEncoder().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}
```

### Right to Rectification (GDPR Art. 16)

```java
/**
 * Servicio para corrección de datos personales.
 */
@Service
public class DataRectificationService {

    private final UserRepository userRepo;
    private final AuditLogRepository auditRepo;

    /**
     * Actualiza datos personales del usuario.
     */
    public Mono<User> rectifyUserData(UUID userId, UserDataUpdate update) {
        return userRepo.findById(userId)
            .flatMap(user -> {
                // Validar cambios
                validateUpdate(update);

                // Aplicar cambios
                if (update.email() != null) {
                    user.setEmail(update.email());
                }
                if (update.phoneNumber() != null) {
                    user.setPhoneNumber(update.phoneNumber());
                }

                return userRepo.save(user)
                    .doOnSuccess(savedUser ->
                        auditRectification(userId, update)
                    );
            });
    }

    private void auditRectification(UUID userId, UserDataUpdate update) {
        auditRepo.save(new AuditLog(
            UUID.randomUUID(),
            userId,
            "DATA_RECTIFICATION",
            Instant.now(),
            null,
            null,
            Map.of("changes", update)
        ));
    }

    private void validateUpdate(UserDataUpdate update) {
        if (update.email() != null && !isValidEmail(update.email())) {
            throw new ValidationException("Invalid email format");
        }
    }
}
```

### Right to Data Portability (GDPR Art. 20)

```java
/**
 * Exporta datos en formato portable y machine-readable.
 */
@Service
public class DataPortabilityService {

    /**
     * Exporta datos en formato JSON estructurado.
     */
    public Mono<PortableDataPackage> exportPortableData(UUID userId) {
        return dataExportService.exportUserData(userId)
            .map(export -> new PortableDataPackage(
                "fantasy-sports-hub",
                "1.0",
                Instant.now(),
                export
            ));
    }

    /**
     * Importa datos desde otro sistema (interoperabilidad).
     */
    public Mono<ImportResult> importPortableData(
        UUID userId,
        PortableDataPackage dataPackage
    ) {
        return validateDataPackage(dataPackage)
            .flatMap(validated -> {
                // Importar solo datos compatibles
                return importTeams(userId, dataPackage.data().teams())
                    .then(importPreferences(userId, dataPackage.data().preferences()))
                    .thenReturn(new ImportResult(true, "Data imported successfully"));
            });
    }
}
```

---

## 🔐 Consent Management

### Consent Types

```java
/**
 * Tipos de consentimiento requeridos.
 */
public enum ConsentType {
    TERMS_OF_SERVICE,      // Obligatorio
    PRIVACY_POLICY,        // Obligatorio
    MARKETING_EMAILS,      // Opcional
    ANALYTICS_TRACKING,    // Opcional
    THIRD_PARTY_SHARING   // Opcional
}

/**
 * Registro de consentimientos.
 */
@Entity
@Table(name = "user_consents")
public class UserConsent {

    @Id
    private UUID id;

    private UUID userId;

    @Enumerated(EnumType.STRING)
    private ConsentType consentType;

    private boolean granted;

    private Instant grantedAt;

    private Instant revokedAt;

    private String ipAddress;

    private String userAgent;

    // Evidencia del consentimiento
    @Column(columnDefinition = "TEXT")
    private String consentText;

    private String consentVersion;
}
```

### Consent Service

```java
/**
 * Gestión de consentimientos.
 */
@Service
public class ConsentService {

    private final ConsentRepository consentRepo;

    /**
     * Registra consentimiento del usuario.
     */
    public Mono<UserConsent> grantConsent(
        UUID userId,
        ConsentType consentType,
        String ipAddress,
        String userAgent
    ) {
        var consent = new UserConsent(
            UUID.randomUUID(),
            userId,
            consentType,
            true,
            Instant.now(),
            null,
            ipAddress,
            userAgent,
            getConsentText(consentType),
            getConsentVersion(consentType)
        );

        return consentRepo.save(consent);
    }

    /**
     * Revoca consentimiento.
     */
    public Mono<UserConsent> revokeConsent(UUID userId, ConsentType consentType) {
        return consentRepo.findByUserIdAndConsentType(userId, consentType)
            .flatMap(consent -> {
                consent.setGranted(false);
                consent.setRevokedAt(Instant.now());
                return consentRepo.save(consent);
            });
    }

    /**
     * Verifica si usuario ha dado consentimiento.
     */
    public Mono<Boolean> hasConsent(UUID userId, ConsentType consentType) {
        return consentRepo.findByUserIdAndConsentType(userId, consentType)
            .map(consent -> consent.granted() && consent.revokedAt() == null)
            .defaultIfEmpty(false);
    }

    /**
     * Obtiene todos los consentimientos de un usuario.
     */
    public Flux<UserConsent> getUserConsents(UUID userId) {
        return consentRepo.findByUserId(userId);
    }

    private String getConsentText(ConsentType consentType) {
        // Obtener texto actual del consentimiento desde configuración
        return "...";
    }

    private String getConsentVersion(ConsentType consentType) {
        // Obtener versión actual del consentimiento
        return "1.0";
    }
}
```

---

## 🚨 Data Breach Notification

### Breach Detection

```java
/**
 * Detección y notificación de brechas de seguridad.
 */
@Service
public class DataBreachService {

    private final NotificationService notificationService;
    private final AuditLogRepository auditRepo;

    /**
     * Registra incidente de seguridad.
     */
    public Mono<DataBreach> reportBreach(
        BreachType breachType,
        Set<UUID> affectedUserIds,
        String description
    ) {
        var breach = new DataBreach(
            UUID.randomUUID(),
            breachType,
            affectedUserIds,
            description,
            Instant.now(),
            BreachStatus.DETECTED,
            calculateSeverity(breachType, affectedUserIds.size())
        );

        return saveAndNotify(breach);
    }

    /**
     * Notifica a usuarios afectados (GDPR Art. 34 - máximo 72h).
     */
    private Mono<DataBreach> saveAndNotify(DataBreach breach) {
        return breachRepo.save(breach)
            .flatMap(savedBreach -> {
                // Notificar a autoridades si es severo (GDPR Art. 33)
                if (breach.severity() == Severity.CRITICAL) {
                    return notifyAuthorities(breach)
                        .then(notifyAffectedUsers(breach))
                        .thenReturn(savedBreach);
                }

                // Solo notificar a usuarios afectados
                return notifyAffectedUsers(breach)
                    .thenReturn(savedBreach);
            });
    }

    /**
     * Notifica a autoridad supervisora (72h desde detección).
     */
    private Mono<Void> notifyAuthorities(DataBreach breach) {
        var notification = BreachNotification.builder()
            .breachId(breach.id())
            .occurredAt(breach.detectedAt())
            .affectedUsers(breach.affectedUserIds().size())
            .dataCategories(extractDataCategories(breach))
            .mitigationMeasures(extractMitigationMeasures(breach))
            .build();

        // Enviar a autoridad supervisora (DPA)
        return supervisoryAuthorityClient.reportBreach(notification);
    }

    /**
     * Notifica a usuarios afectados por la brecha.
     */
    private Mono<Void> notifyAffectedUsers(DataBreach breach) {
        return Flux.fromIterable(breach.affectedUserIds())
            .flatMap(userId ->
                userRepo.findById(userId)
                    .flatMap(user ->
                        notificationService.sendEmail(
                            user.email(),
                            "Security Incident Notification",
                            buildBreachNotificationEmail(breach)
                        )
                    )
            )
            .then();
    }

    private Severity calculateSeverity(BreachType type, int affectedUsers) {
        if (affectedUsers > 10000 || type == BreachType.FINANCIAL_DATA) {
            return Severity.CRITICAL;
        }
        if (affectedUsers > 1000) {
            return Severity.HIGH;
        }
        return Severity.MEDIUM;
    }

    private String buildBreachNotificationEmail(DataBreach breach) {
        return String.format("""
            Dear User,

            We are writing to inform you about a security incident that may have affected your data.

            What happened: %s
            When: %s
            Data affected: %s

            What we're doing:
            - We have taken immediate steps to secure our systems
            - We are investigating the incident thoroughly
            - We have notified the appropriate authorities

            What you should do:
            - Change your password immediately
            - Enable two-factor authentication
            - Monitor your account for suspicious activity

            We sincerely apologize for this incident.

            Best regards,
            Fantasy Sports Hub Security Team
            """,
            breach.description(),
            breach.detectedAt(),
            extractDataCategories(breach)
        );
    }
}
```

---

## 📊 Privacy by Design

### Data Minimization

```java
/**
 * Principio de minimización de datos.
 * Solo recolectar datos estrictamente necesarios.
 */
@Service
public class DataMinimizationService {

    /**
     * Valida que solo se recolecten datos necesarios.
     */
    public void validateDataCollection(UserRegistration registration) {
        // Email: Necesario para autenticación
        requireNonNull(registration.email(), "Email is required");

        // Teléfono: OPCIONAL, solo para MFA
        if (registration.phoneNumber() != null) {
            log.info("Phone number provided for MFA purposes");
        }

        // Fecha de nacimiento: NO NECESARIA (no recolectar)
        if (registration.dateOfBirth() != null) {
            throw new ValidationException(
                "Date of birth is not required and should not be provided"
            );
        }

        // Dirección: NO NECESARIA (no recolectar)
        if (registration.address() != null) {
            throw new ValidationException(
                "Address is not required and should not be provided"
            );
        }
    }
}
```

### Data Retention

```java
/**
 * Políticas de retención de datos.
 */
@Configuration
public class DataRetentionPolicy {

    /**
     * Ejecuta limpieza de datos antiguos.
     */
    @Scheduled(cron = "0 0 2 * * *")  // 2 AM daily
    public void enforceRetentionPolicy() {
        var cutoffDate = Instant.now().minus(Duration.ofDays(365 * 6));

        // Eliminar audit logs > 6 años (excepto fraude)
        deleteOldAuditLogs(cutoffDate);

        // Eliminar cuentas inactivas > 2 años
        deleteInactiveAccounts(Instant.now().minus(Duration.ofDays(365 * 2)));

        // Anonimizar eventos > 1 año
        anonymizeOldEvents(Instant.now().minus(Duration.ofDays(365)));
    }

    private void deleteOldAuditLogs(Instant cutoff) {
        auditRepo.deleteByTimestampBeforeAndNotFraudRelated(cutoff);
    }

    private void deleteInactiveAccounts(Instant cutoff) {
        userRepo.findInactiveSince(cutoff)
            .flatMap(user -> dataErasureService.eraseUserData(
                user.id(),
                ErasureReason.RETENTION_POLICY
            ))
            .subscribe();
    }
}
```

---
