package com.borrowservice.infrastructure.scheduler;

import com.borrowservice.application.port.in.MarkOverdueBorrowsUseCase;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class OverdueBorrowScheduler {

    private final MarkOverdueBorrowsUseCase markOverdueBorrowsUseCase;

    public OverdueBorrowScheduler(MarkOverdueBorrowsUseCase markOverdueBorrowsUseCase) {
        this.markOverdueBorrowsUseCase = markOverdueBorrowsUseCase;
    }

    @Scheduled(cron = "0 1 0 * * *")
    public void scheduleOverdueCheck() {
        System.out.println("Running nightly overdue check job...");
        markOverdueBorrowsUseCase.markOverdue();
    }
}