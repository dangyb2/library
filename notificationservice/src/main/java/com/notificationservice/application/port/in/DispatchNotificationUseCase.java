package com.notificationservice.application.port.in;

public interface DispatchNotificationUseCase {
    void dispatchFromQueue(String notificationId);
}