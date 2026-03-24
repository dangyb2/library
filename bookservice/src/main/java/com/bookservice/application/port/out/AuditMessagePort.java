package com.bookservice.application.port.out;

public interface AuditMessagePort {
    void sendBookEvent(String eventType, String aggregateId, String message);

    void sendDeleteBookEvent(String eventType, String aggregateId, String message);
}