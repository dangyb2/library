package com.auditservice.infrastructure.persistence;

import com.auditservice.domain.model.AuditLog;
import com.auditservice.domain.model.EventType;
import com.auditservice.application.port.out.AuditLogRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public class JpaAuditLogRepository implements AuditLogRepository {

    private final SpringDataAuditLogRepository jpaRepository;

    public JpaAuditLogRepository(SpringDataAuditLogRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public void save(AuditLog auditLog) {
        jpaRepository.save(AuditLogMapper.toEntity(auditLog));
    }

    @Override
    public List<AuditLog> findAll() {
        return jpaRepository.findAll()
                .stream()
                .map(AuditLogMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<AuditLog> findById(String id) {
        return jpaRepository.findById(id)
                .map(AuditLogMapper::toDomain);
    }

    @Override
    public List<AuditLog> findByAggregateId(String aggregateId) {
        return jpaRepository.findByAggregateId(aggregateId)
                .stream()
                .map(AuditLogMapper::toDomain)
                .toList();
    }

    @Override
    public List<AuditLog> findByEventType(EventType eventType) {
        return jpaRepository.findByEventType(eventType)
                .stream()
                .map(AuditLogMapper::toDomain)
                .toList();
    }

    @Override
    public List<AuditLog> findByDateRange(Instant from, Instant to) {
        return jpaRepository.findByOccurredAtBetween(from, to)
                .stream()
                .map(AuditLogMapper::toDomain)
                .toList();
    }


}