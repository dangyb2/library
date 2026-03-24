package com.auditservice.domain.exception;

public class UnknownEventTypeException extends RuntimeException {
    public UnknownEventTypeException(String receivedType) {
        super("Unknown event type received: '" + receivedType + "'");
    }
}