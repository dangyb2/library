package com.notificationservice.application.port.in;

public interface RetryNotificationUseCase {
    void retry(String id);
}