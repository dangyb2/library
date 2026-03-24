package com.auditservice.application.service;

import com.auditservice.application.dto.AuditLogSummaryView;
import com.auditservice.application.port.in.GetAuditLogsByEventTypeUseCase;
import com.auditservice.application.port.out.AuditLogRepository;
import com.auditservice.domain.model.EventType;

import java.util.List;

public class GetAuditLogsByEventTypeService implements GetAuditLogsByEventTypeUseCase {
    private final AuditLogRepository repository;

    public GetAuditLogsByEventTypeService(AuditLogRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<AuditLogSummaryView> get(String eventType) {
        EventType type = EventType.from(eventType);
        return repository.findByEventType(type)
                .stream()
                .map(AuditLogSummaryView::from)
                .toList();
    }
}