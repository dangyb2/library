package com.borrowservice.infrastructure.messaging;

import com.borrowservice.application.port.out.NotificationPort;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Component
public class KafkaNotificationAdapter implements NotificationPort {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    // This MUST match the 'dispatch-topic' in your Notification Service config
    private static final String TOPIC = "notification.events";

    public KafkaNotificationAdapter(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public void sendNotification(String type, String recipientEmail, Map<String, Object> variables) {
        // expected by the NotificationEventRequest record in your Notification Service.
        Map<String, Object> payload = new HashMap<>();
        payload.put("type", type);
        payload.put("recipientEmail", recipientEmail);
        payload.put("variables", variables);

        System.out.println("Publishing notification event to Kafka for: " + recipientEmail);
        kafkaTemplate.send(TOPIC, payload);
    }
}