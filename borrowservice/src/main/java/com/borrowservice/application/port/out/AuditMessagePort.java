package com.borrowservice.application.port.out;

public interface AuditMessagePort {
    void sendBorrowEvent(String eventType, String aggregateId, String message);
}