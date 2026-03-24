package com.auditservice.infrastructure.persistence;

import com.auditservice.domain.model.AuditLog;

public class AuditLogMapper {

    private AuditLogMapper() {}

    public static AuditLogEntity toEntity(AuditLog log) {
        // Use the new all-args constructor instead of setters!
        return new AuditLogEntity(
                log.getId(),
                log.getEventType(),
                log.getAggregateId(),
                log.getMessage(),
                log.getOccurredAt()
        );
    }

    public static AuditLog toDomain(AuditLogEntity entity) {
        return AuditLog.reconstruct(
                entity.getId(),
                entity.getEventType(),
                entity.getAggregateId(),
                entity.getMessage(),
                entity.getOccurredAt()
        );
    }
}