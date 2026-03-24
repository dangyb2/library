package com.auditservice.domain.exception;

public class AuditLogNotFoundException extends RuntimeException {
    public AuditLogNotFoundException(String id) {
        super("Audit log not found: " + id);
    }
}