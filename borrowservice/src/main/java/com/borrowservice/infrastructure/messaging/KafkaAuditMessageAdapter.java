package com.borrowservice.infrastructure.messaging;

import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.infrastructure.messaging.dto.AuditEventPayload;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class KafkaAuditMessageAdapter implements AuditMessagePort {

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private static final String TOPIC = "audit-events";

    public KafkaAuditMessageAdapter(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public void sendBorrowEvent(String eventType, String aggregateId, String message) {

        AuditEventPayload payload = new AuditEventPayload(
                eventType,
                aggregateId,
                message,
                Instant.now().toString()
        );
        kafkaTemplate.send(TOPIC, aggregateId, payload);

        System.out.println("Published " + eventType + " event for ID: " + aggregateId);
    }
}