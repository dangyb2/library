package com.readerservice.infrastructure.messaging;

import com.readerservice.application.port.out.NotificationPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Component
public class KafkaNotificationAdapter implements NotificationPort {
    private static final Logger log = LoggerFactory.getLogger(KafkaNotificationAdapter.class);
    private static final String TOPIC = "notification.events";

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public KafkaNotificationAdapter(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public void sendNotification(String type, String recipientEmail, Map<String, Object> variables) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("type", type);
        payload.put("recipientEmail", recipientEmail);
        payload.put("variables", variables);

        kafkaTemplate.send(TOPIC, payload);
        log.info("Đã đẩy notification type={} cho email={}", type, recipientEmail);
    }
}
