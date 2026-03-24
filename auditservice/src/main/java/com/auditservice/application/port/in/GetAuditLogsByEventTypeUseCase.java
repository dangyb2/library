package com.auditservice.application.port.in;


import com.auditservice.application.dto.AuditLogSummaryView;

import java.util.List;

public interface GetAuditLogsByEventTypeUseCase {
    List<AuditLogSummaryView> get(String eventType);

}

