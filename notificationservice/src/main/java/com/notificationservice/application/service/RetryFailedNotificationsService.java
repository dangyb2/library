package com.notificationservice.application.service;

import com.notificationservice.application.port.in.RetryFailedNotificationsUseCase;
import com.notificationservice.application.port.out.NotificationDispatchPublisher;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.exception.NotificationPublishException;
import com.notificationservice.domain.model.Notification;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class RetryFailedNotificationsService implements RetryFailedNotificationsUseCase {

    private static final Logger log = LoggerFactory.getLogger(RetryFailedNotificationsService.class);

    private final NotificationRepository notificationRepository;
    private final NotificationDispatchPublisher dispatchPublisher;

    private final int maxAttempts;
    private final int batchSize;

    public RetryFailedNotificationsService(
            NotificationRepository notificationRepository,
            NotificationDispatchPublisher dispatchPublisher,
            // 🚀 Inject the values directly from application.yml
            @Value("${notification.retry.max-attempts:3}") int maxAttempts,
            @Value("${notification.retry.batch-size:50}") int batchSize
    ) {
        this.notificationRepository = notificationRepository;
        this.dispatchPublisher = dispatchPublisher;
        this.maxAttempts = maxAttempts;
        this.batchSize = batchSize;
    }

    @Override
    public int retryFailed() {
        List<Notification> failed = notificationRepository.findFailed(maxAttempts, batchSize);
        int processed = 0;

        for (Notification notification : failed) {
            try {
                dispatchPublisher.publish(notification.getId());
                processed += 1;

            } catch (NotificationPublishException ex) {
                log.warn("Message broker unavailable for notification {}. Will retry next batch.",
                        notification.getId());
            }
        }
        return processed;
    }
}