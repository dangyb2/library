package com.borrowservice.application.port.out;

import java.util.Map;

public interface NotificationPort {
    void sendNotification(String type, String recipientEmail, Map<String, Object> variables);
}