package com.auditservice.infrastructure.messaging.dto;


public record AuditEventPayload(
        String eventType,
        String aggregateId,
        String message,
        String occurredAt
) {}