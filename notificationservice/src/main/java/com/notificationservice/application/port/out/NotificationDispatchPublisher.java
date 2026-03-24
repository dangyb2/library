package com.notificationservice.application.port.out;

public interface NotificationDispatchPublisher {
    void publish(String notificationId);
}
