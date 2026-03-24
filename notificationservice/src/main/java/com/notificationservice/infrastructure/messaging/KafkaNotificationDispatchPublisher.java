package com.notificationservice.infrastructure.messaging;

import com.notificationservice.domain.exception.NotificationPublishException;
import com.notificationservice.application.port.out.NotificationDispatchPublisher;
import com.notificationservice.infrastructure.config.NotificationProperties;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
public class KafkaNotificationDispatchPublisher implements NotificationDispatchPublisher {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final NotificationProperties properties;

    public KafkaNotificationDispatchPublisher(
            @Qualifier("stringKafkaTemplate") KafkaTemplate<String, String> kafkaTemplate,
            NotificationProperties properties
    ) {
        this.kafkaTemplate = kafkaTemplate;
        this.properties = properties;
    }

    @Override
    public void publish(String notificationId) {
        try {
            kafkaTemplate.send(properties.kafka().dispatchTopic(), notificationId, notificationId).get();
        } catch (Exception ex) {
            throw new NotificationPublishException(notificationId, ex);
        }
    }
}