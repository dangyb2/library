package com.bookservice.infrastructure.messaging;

import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.infrastructure.messaging.dto.AuditEventPayload;
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
    public void sendBookEvent(String eventType, String aggregateId, String message) {
        publishToKafka(eventType, aggregateId, message);
    }

    @Override
    public void sendDeleteBookEvent(String eventType, String aggregateId, String message) {
        publishToKafka(eventType, aggregateId, message);
    }

    private void publishToKafka(String eventType, String aggregateId, String message) {
        AuditEventPayload payload = new AuditEventPayload(
                eventType,
                aggregateId,
                message,
                Instant.now().toString()
        );

        kafkaTemplate.send(TOPIC, aggregateId, payload);
        System.out.println("Published " + eventType + " event for book ID: " + aggregateId);
    }
}