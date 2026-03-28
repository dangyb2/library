package com.notificationservice.application.util;

import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class NotificationIdGenerator {
    public String newId() {
        return "MAIL-" + UUID.randomUUID();
    }
}
