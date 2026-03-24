package com.auditservice.domain.exception;

public class InvalidAuditLogException extends RuntimeException {
    private final String field;

    public InvalidAuditLogException(String field, String reason) {
        super("Invalid audit log — " + field + ": " + reason);
        this.field = field;
    }

    public String getField() { return field; }
}