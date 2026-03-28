package com.notificationservice.application.service;

import com.notificationservice.application.port.in.RetryNotificationUseCase;
import com.notificationservice.application.port.out.NotificationDispatchPublisher;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.exception.NotificationNotFoundException;
import com.notificationservice.domain.exception.InvalidNotificationStateException;
import com.notificationservice.domain.model.Notification;
import com.notificationservice.domain.model.NotificationStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RetryNotificationService implements RetryNotificationUseCase {

    private final NotificationRepository repository;
    private final NotificationDispatchPublisher publisher;

    public RetryNotificationService(NotificationRepository repository, NotificationDispatchPublisher publisher) {
        this.repository = repository;
        this.publisher = publisher;
    }

    @Override
    @Transactional
    public void retry(String id) {
        Notification notification = repository.findById(id)
                .orElseThrow(() -> new NotificationNotFoundException("Notification not found: " + id));

        // 🛡️ Business Rule: Don't waste resources resending what's already delivered
        if (notification.getStatus() == NotificationStatus.SENT) {
            throw new InvalidNotificationStateException("Cannot retry a notification that is already SENT.");
        }

        // 🚀 Push the ID back to the 'notification.dispatch' Kafka topic
        publisher.publish(notification.getId());
    }
}