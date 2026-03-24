package com.notificationservice.domain.exception;

public class NotificationPublishException extends RuntimeException {
    public NotificationPublishException(String notificationId, Throwable cause) {
        super("Failed to publish notification dispatch event for id: " + notificationId, cause);
    }
}
