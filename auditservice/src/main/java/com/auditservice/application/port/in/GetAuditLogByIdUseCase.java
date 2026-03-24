package com.auditservice.application.port.in;


import com.auditservice.application.dto.AuditLogSummaryView;

public interface GetAuditLogByIdUseCase {
    AuditLogSummaryView get(String id);
}
