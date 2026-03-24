package com.notificationservice.domain.exception;

import com.notificationservice.domain.model.NotificationType;

public class TemplateNotFoundException extends RuntimeException {
    public TemplateNotFoundException(NotificationType type) {
        super("No template configured for type: " + type);
    }
}
