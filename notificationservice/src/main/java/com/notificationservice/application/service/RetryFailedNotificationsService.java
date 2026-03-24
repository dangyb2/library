package com.notificationservice.application.service;

import com.notificationservice.application.port.in.RetryFailedNotificationsUseCase;
import com.notificationservice.application.port.out.NotificationDispatchPublisher;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.model.Notification;
import com.notificationservice.infrastructure.config.NotificationProperties;
import org.springframework.stereotype.Service;

import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
@Service
public class RetryFailedNotificationsService implements RetryFailedNotificationsUseCase {
    private final NotificationRepository notificationRepository;
    private final NotificationDispatchPublisher dispatchPublisher;
    private final NotificationProperties properties;
    private static final Logger log = LoggerFactory.getLogger(RetryFailedNotificationsService.class);
    public RetryFailedNotificationsService(
            NotificationRepository notificationRepository,
            NotificationDispatchPublisher dispatchPublisher,
            NotificationProperties properties
    ) {
        this.notificationRepository = notificationRepository;
        this.dispatchPublisher = dispatchPublisher;
        this.properties = properties;
    }
    @Override
    public int retryFailed() {
        int maxAttempts = properties.retry().maxAttempts();
        int batchSize = properties.retry().batchSize();
        List<Notification> failed = notificationRepository.findFailed(maxAttempts, batchSize);
        int processed = 0;

        for (Notification notification : failed) {
            try {
                dispatchPublisher.publish(notification.getId());
                processed += 1;
            } catch (Exception ex) {
                log.error("Critical failure processing retry for notification {}. Skipping to next.",
                        notification.getId(), ex);
            }
        }

        return processed;
    }
}
