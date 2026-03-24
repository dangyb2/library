package com.auditservice.application.service;

import com.auditservice.application.dto.AuditLogSummaryView;
import com.auditservice.application.port.in.GetAuditLogByIdUseCase;
import com.auditservice.application.port.out.AuditLogRepository;
import com.auditservice.domain.exception.AuditLogNotFoundException;
import com.auditservice.domain.exception.InvalidAuditLogException;

public class GetAuditLogByIdService implements GetAuditLogByIdUseCase {

    private final AuditLogRepository repository;

    public GetAuditLogByIdService(AuditLogRepository repository) {
        this.repository = repository;
    }

    @Override
    public AuditLogSummaryView get(String id) {
        if (id == null || id.isBlank())
            throw new InvalidAuditLogException("id", "must not be null or blank");

        return repository.findById(id)
                .map(AuditLogSummaryView::from)
                .orElseThrow(() -> new AuditLogNotFoundException(id));
    }
}