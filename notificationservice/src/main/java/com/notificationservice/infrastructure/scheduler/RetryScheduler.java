package com.notificationservice.infrastructure.scheduler;

import com.notificationservice.application.port.in.RetryFailedNotificationsUseCase;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class RetryScheduler {
    private final RetryFailedNotificationsUseCase retryUseCase;

    public RetryScheduler(RetryFailedNotificationsUseCase retryUseCase) {
        this.retryUseCase = retryUseCase;
    }

    @Scheduled(fixedDelayString = "${notification.retry.delay-ms:60000}")
    public void retryFailed() {
        retryUseCase.retryFailed();
    }
}
