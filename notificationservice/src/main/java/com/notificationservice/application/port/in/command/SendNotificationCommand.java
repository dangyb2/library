package com.notificationservice.application.port.in.command;

import com.notificationservice.domain.model.NotificationType;

import java.util.Map;

public record SendNotificationCommand(NotificationType type, String recipientEmail, Map<String, Object> variables) {
}
