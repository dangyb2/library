package com.auditservice.domain.model;

import com.auditservice.domain.exception.InvalidAuditLogException;

import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

public final class AuditLog {

    private final String id;
    private final EventType eventType;
    private final String aggregateId;
    private final String message;
    private final Instant occurredAt;

    // 1. Private Constructor: Takes ALL fields, including ID.
    // It does NOT generate anything, it just assigns and validates.
    private AuditLog(String id, EventType eventType, String aggregateId,

                     String message, Instant occurredAt) {

        this.id          = requireValid(id,          "id");
        this.eventType   = requireValid(eventType,   "eventType");
        this.aggregateId = requireValid(aggregateId, "aggregateId");
        this.message     = requireValid(message,     "message");
        this.occurredAt  = requireValid(occurredAt,  "occurredAt");
    }

    private static <T> T requireValid(T value, String field) {
        if (value == null)
            throw new InvalidAuditLogException(field, "must not be null");
        if (value instanceof String s && s.isBlank())
            throw new InvalidAuditLogException(field, "must not be blank");
        return value;
    }

    // 2. Factory for NEW Logs: Generates the ID here.
    public static AuditLog create(EventType eventType, String aggregateId,

                                  String message, Instant occurredAt) {

        if (eventType == null)
            throw new InvalidAuditLogException("eventType", "must not be null");


        // Generate the friendly ID based on the occurredAt time
        String generatedId = String.format("LOG-%s-%s",
                occurredAt.atZone(ZoneOffset.UTC).format(DateTimeFormatter.ofPattern("yyyyMMdd")),
                UUID.randomUUID().toString().substring(0, 8).toUpperCase());

        return new AuditLog(generatedId, eventType, aggregateId,  message, occurredAt);
    }

    // 3. Factory for EXISTING Logs: Takes the existing ID from the database.
    public static AuditLog reconstruct(String id, EventType eventType, String aggregateId,

                                       String message, Instant occurredAt) {

        // Just passes the existing ID straight through to the constructor
        return new AuditLog(id, eventType, aggregateId,  message, occurredAt);
    }

    // --- GETTERS ---
    public String getId()          { return id; }
    public EventType getEventType(){ return eventType; }
    public String getAggregateId() { return aggregateId; }
    public String getMessage()     { return message; }
    public Instant getOccurredAt() { return occurredAt; }
}