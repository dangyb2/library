package com.auditservice.application.port.in;

import com.auditservice.application.port.in.command.RecordAuditLogCommand;

public interface RecordAuditLogUseCase {
    void recordLog(RecordAuditLogCommand payload);
}