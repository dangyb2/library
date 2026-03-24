package com.auditservice.application.service;

import com.auditservice.application.dto.AuditLogSummaryView;
import com.auditservice.application.port.in.GetAllAuditLogsUseCase;
import com.auditservice.application.port.out.AuditLogRepository;

import java.util.List;

public class GetAllAuditLogsService implements GetAllAuditLogsUseCase {

    private final AuditLogRepository repository;

    public GetAllAuditLogsService(AuditLogRepository repository) {
        this.repository = repository;
    }
    @Override
    public List<AuditLogSummaryView> get() {
        return repository.findAll()
                .stream()
                .map(AuditLogSummaryView::from)
                .toList();
    }


}