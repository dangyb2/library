package com.notificationservice.infrastructure.dto;

import com.notificationservice.domain.model.NotificationType;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.Map;

public record NotificationEventRequest(
        @NotNull NotificationType type,
        @NotBlank @Email String recipientEmail,
        Map<String, Object> variables
) {
}
