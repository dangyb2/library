package com.auditservice.infrastructure.messaging;

import com.auditservice.application.port.in.RecordAuditLogUseCase;
import com.auditservice.application.port.in.command.RecordAuditLogCommand;
import com.auditservice.infrastructure.messaging.dto.AuditEventPayload;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class KafkaAuditListener {

    private final RecordAuditLogUseCase recordAuditLogUseCase;

    public KafkaAuditListener(RecordAuditLogUseCase recordAuditLogUseCase) {
        this.recordAuditLogUseCase = recordAuditLogUseCase;
    }

    @KafkaListener(topics = "audit-events", groupId = "audit-service-group")
    public void consumeAuditEvent(AuditEventPayload payload) {
        RecordAuditLogCommand command = new RecordAuditLogCommand(
                payload.eventType(),
                payload.aggregateId(),
                payload.message(),
                payload.occurredAt()
        );

        recordAuditLogUseCase.recordLog(command);
    }
}