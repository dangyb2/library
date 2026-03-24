package com.notificationservice.application.port.out;

import com.notificationservice.domain.model.Notification;
import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface NotificationRepository {
    Notification save(Notification notification);

    List<Notification> findFailed(int maxRetry, int limit);

    Optional<Notification> findById(String id);

    List<Notification> search(
            String id,
            String recipientEmail,
            NotificationType type,
            NotificationStatus status,
            Instant fromDate,
            Instant toDate
    );
}
