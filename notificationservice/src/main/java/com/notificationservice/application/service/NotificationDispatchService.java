package com.notificationservice.application.service;

import com.notificationservice.application.port.in.DispatchNotificationUseCase;
import com.notificationservice.application.port.out.EmailSender;
import com.notificationservice.application.port.out.NotificationRepository;
import com.notificationservice.domain.exception.NotificationPublishException;
import com.notificationservice.domain.model.Notification;
import com.notificationservice.domain.model.NotificationStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;

@Service
public class NotificationDispatchService implements DispatchNotificationUseCase {
    private static final Logger log = LoggerFactory.getLogger(NotificationDispatchService.class);

    private final NotificationRepository notificationRepository;
    private final EmailSender emailSender;
    private final Clock clock;

    @Value("${notification.retry.max-attempts:3}")
    private int maxAttempts;

    public NotificationDispatchService(
            NotificationRepository notificationRepository,
            EmailSender emailSender,
            Clock clock
    ) {
        this.notificationRepository = notificationRepository;
        this.emailSender = emailSender;
        this.clock = clock;
    }

    @Override
    @Transactional
    public void dispatchFromQueue(String notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElse(null);

        // 1. Basic Validation
        if (notification == null) {
            log.warn("Notification {} not found, skip dispatch", notificationId);
            return;
        }

        // 2. State Check
        if (notification.getStatus() == NotificationStatus.SENT) {
            log.info("Notification {} already sent. Skip duplicate dispatch.", notificationId);
            return;
        }

        // 3. Retry Limit Check (Using the injected maxAttempts)
        if (notification.getRetryCount() >= maxAttempts) {
            log.error("Notification {} has reached max retry attempts ({}). Stopping dispatch.",
                    notificationId, maxAttempts);
            // Optional: notification.markAsPermanentlyFailed();
            return;
        }

        try {
            // 4. Execution
            emailSender.send(
                    notification.getRecipientEmail(),
                    notification.getSubject(),
                    notification.getContent()
            );

            notification.markSent(clock.instant());
            log.info("Successfully sent notification {}", notificationId);

            // 🚀 ONLY catch the specific exception related to sending failures!
        } catch (NotificationPublishException ex) {
            // 5. Error Handling for Delivery Failures
            notification.incrementRetry();
            notification.markFailed();

            log.warn("Failed to deliver notification {} (Attempt {}/{}): {}",
                    notificationId, notification.getRetryCount(), maxAttempts, ex.getMessage());
        }

        notificationRepository.save(notification);
    }
}