package com.auditservice.application.port.out;

import com.auditservice.domain.model.AuditLog;
import com.auditservice.domain.model.EventType;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface AuditLogRepository {
    void save(AuditLog auditLog);
    List<AuditLog> findAll();
    Optional<AuditLog> findById(String id);
    List<AuditLog> findByAggregateId(String aggregateId);
    List<AuditLog> findByEventType(EventType eventType);
    List<AuditLog> findByDateRange(Instant from, Instant to);
}