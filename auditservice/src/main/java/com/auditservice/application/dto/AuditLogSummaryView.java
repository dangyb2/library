package com.auditservice.application.dto;

import com.auditservice.domain.model.AuditLog;

import java.time.Instant;

public record AuditLogSummaryView(
        String id,
        String eventType,
        String aggregateId,
        String message,
        Instant occurredAt
) {
    public static AuditLogSummaryView from(AuditLog log) {
        return new AuditLogSummaryView(
                log.getId(),
                log.getEventType().name(),
                log.getAggregateId(),
                log.getMessage(),
                log.getOccurredAt()
        );
    }
}