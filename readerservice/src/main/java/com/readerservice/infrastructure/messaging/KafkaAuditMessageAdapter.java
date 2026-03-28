package com.readerservice.infrastructure.messaging;

import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.infrastructure.messaging.dto.AuditEventPayload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class KafkaAuditMessageAdapter implements AuditMessagePort {
    private static final Logger log = LoggerFactory.getLogger(KafkaAuditMessageAdapter.class);
    private static final String TOPIC = "audit-events";

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public KafkaAuditMessageAdapter(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public void sendReaderEvent(String eventType, String aggregateId, String message) {
        AuditEventPayload payload = new AuditEventPayload(
                eventType,
                aggregateId,
                message,
                Instant.now().toString()
        );
        kafkaTemplate.send(TOPIC, aggregateId, payload);
        log.info("Đã đẩy audit event={} cho readerId={}", eventType, aggregateId);
    }
}
