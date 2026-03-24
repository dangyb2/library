package com.auditservice.application.service;

import com.auditservice.application.dto.AuditLogSummaryView;
import com.auditservice.application.port.in.GetAuditLogsByAggregateIdUseCase;
import com.auditservice.application.port.out.AuditLogRepository;

import java.util.List;

public class GetAuditLogsByAggregateIdService implements GetAuditLogsByAggregateIdUseCase {

    private final AuditLogRepository repository;

    public GetAuditLogsByAggregateIdService(AuditLogRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<AuditLogSummaryView> get(String aggregateId) {
        return repository.findByAggregateId(aggregateId)
                .stream()
                .map(AuditLogSummaryView::from)
                .toList();
    }
}