package com.auditservice.application.port.in;

import com.auditservice.application.dto.AuditLogSummaryView;

import java.util.List;

public interface GetAuditLogsByDateRangeUseCase {
    List<AuditLogSummaryView> get(String from, String to);
}