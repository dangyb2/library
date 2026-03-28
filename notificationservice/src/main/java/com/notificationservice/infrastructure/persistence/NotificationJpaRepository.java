package com.notificationservice.infrastructure.persistence;

import com.notificationservice.domain.model.NotificationStatus;
import com.notificationservice.domain.model.NotificationType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;

public interface NotificationJpaRepository extends JpaRepository<NotificationEntity, String> {

    List<NotificationEntity> findByStatusAndRetryCountLessThanOrderByCreatedAtAsc(
            NotificationStatus status,
            int retryCount,
            Pageable pageable
    );
    List<NotificationEntity> findByStatus(NotificationStatus status);
    List<NotificationEntity> findByType(NotificationType type);
    List<NotificationEntity> findByRecipientEmail(String recipientEmail);
    List<NotificationEntity> findByCreatedAtBetween(Instant startDate, Instant endDate);
}