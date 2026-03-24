package com.notificationservice.application.port.in.query;

import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;

import java.time.Instant;

public record NotificationSearchQuery(
        String id,
        String recipientEmail,
        NotificationType type,
        NotificationStatus status,
        Instant fromDate,
        Instant toDate
) {
}
