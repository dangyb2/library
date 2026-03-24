package com.auditservice.infrastructure.persistence;

import com.auditservice.domain.model.EventType;
import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.Nationalized;

import java.time.Instant;

@Entity
@Table(name = "audit_logs")
@Immutable // Tells Hibernate this entity is read-only, improving performance
public class AuditLogEntity {

    @Id
    @Column(updatable = false)
    private String id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false)
    private EventType eventType;

    @Column(nullable = false, updatable = false)
    private String aggregateId;

    @Nationalized
    @Column(nullable = false, updatable = false)
    private String message;
    @Column(nullable = false, updatable = false)
    private Instant occurredAt;

    // 1. Default constructor required by JPA
    protected AuditLogEntity() {}

    // 2. All-args constructor for your Mapper to use
    public AuditLogEntity(String id, EventType eventType, String aggregateId,
                          String message, Instant occurredAt) {
        this.id = id;
        this.eventType = eventType;
        this.aggregateId = aggregateId;

        this.message = message;
        this.occurredAt = occurredAt;
    }

    // --- GETTERS ONLY (No Setters!) ---

    public String getId() { return id; }
    public EventType getEventType() { return eventType; }
    public String getAggregateId() { return aggregateId; }

    public String getMessage() { return message; }
    public Instant getOccurredAt() { return occurredAt; }
}