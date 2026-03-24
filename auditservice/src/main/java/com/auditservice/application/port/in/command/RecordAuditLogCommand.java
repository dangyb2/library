package com.auditservice.application.port.in.command;

public record RecordAuditLogCommand(
        String eventType,
        String aggregateId,

        String message,
        String occurredAt
) {}