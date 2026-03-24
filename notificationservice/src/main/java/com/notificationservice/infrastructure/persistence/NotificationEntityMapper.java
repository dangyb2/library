package com.notificationservice.infrastructure.persistence;

import com.notificationservice.domain.model.Notification;
import org.springframework.stereotype.Component;

@Component
public class NotificationEntityMapper {
    public NotificationEntity toEntity(Notification notification) {
        NotificationEntity entity = new NotificationEntity();
        entity.setId(notification.getId());
        entity.setRecipientEmail(notification.getRecipientEmail());
        entity.setType(notification.getType());
        entity.setSubject(notification.getSubject());
        entity.setContent(notification.getContent());
        entity.setStatus(notification.getStatus());
        entity.setRetryCount(notification.getRetryCount());
        entity.setCreatedAt(notification.getCreatedAt());
        entity.setSentAt(notification.getSentAt());
        return entity;
    }

    public Notification toDomain(NotificationEntity entity) {
        return Notification.restore(
                entity.getId(),
                entity.getRecipientEmail(),
                entity.getType(),
                entity.getSubject(),
                entity.getContent(),
                entity.getStatus(),
                entity.getRetryCount(),
                entity.getCreatedAt(),
                entity.getSentAt()
        );
    }
}
