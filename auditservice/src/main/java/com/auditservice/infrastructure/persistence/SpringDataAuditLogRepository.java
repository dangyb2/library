package com.auditservice.infrastructure.persistence;

import com.auditservice.domain.model.EventType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface SpringDataAuditLogRepository extends JpaRepository<AuditLogEntity, String> {
    List<AuditLogEntity> findByAggregateId(String aggregateId);
    List<AuditLogEntity> findByEventType(EventType eventType);
    List<AuditLogEntity> findByOccurredAtBetween(Instant from, Instant to);
}