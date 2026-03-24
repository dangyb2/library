package com.auditservice.application.service;

import com.auditservice.application.port.in.RecordAuditLogUseCase;
import com.auditservice.application.port.in.command.RecordAuditLogCommand;
import com.auditservice.application.port.out.AuditLogRepository;
import com.auditservice.application.util.InstantParser;
import com.auditservice.domain.exception.InvalidAuditLogException;
import com.auditservice.domain.model.AuditLog;
import com.auditservice.domain.model.EventType;

import java.time.Instant;
import java.time.format.DateTimeParseException;

public class RecordAuditLogService implements RecordAuditLogUseCase {

    private final AuditLogRepository repository;

    public RecordAuditLogService(AuditLogRepository repository) {
        this.repository = repository;
    }

    @Override
    public void recordLog(RecordAuditLogCommand command) {
        EventType eventType = EventType.from(command.eventType());

        Instant occurredAt = InstantParser.parse(command.occurredAt(), "occurredAt");

        AuditLog auditLog = AuditLog.create(
                eventType,
                command.aggregateId(),

                command.message(),
                occurredAt
        );

        repository.save(auditLog);
    }


}