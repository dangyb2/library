package com.notificationservice.infrastructure.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "notification")
public record NotificationProperties(Retry retry, Kafka kafka) {
    public NotificationProperties {
        if (retry == null) {
            retry = new Retry(3, 50, 60000);
        }
        if (kafka == null) {
            kafka = new Kafka("notification.dispatch");
        }
    }

    public record Retry(int maxAttempts, int batchSize, long delayMs) {
        public Retry {
            if (maxAttempts <= 0) {
                maxAttempts = 3;
            }
            if (batchSize <= 0) {
                batchSize = 50;
            }
            if (delayMs <= 0) {
                delayMs = 60000;
            }
        }
    }

    public record Kafka(String dispatchTopic) {
        public Kafka {
            if (dispatchTopic == null || dispatchTopic.isBlank()) {
                dispatchTopic = "notification.dispatch";
            }
        }
    }
}
