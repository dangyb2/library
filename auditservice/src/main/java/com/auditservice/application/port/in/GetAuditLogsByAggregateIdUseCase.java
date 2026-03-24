package com.auditservice.application.port.in;

import com.auditservice.application.dto.AuditLogSummaryView;

import java.util.List;

public interface GetAuditLogsByAggregateIdUseCase {
    List<AuditLogSummaryView> get(String aggregateId);
}
