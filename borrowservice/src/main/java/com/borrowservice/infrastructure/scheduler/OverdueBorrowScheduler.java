package com.borrowservice.infrastructure.scheduler;

import com.borrowservice.application.port.in.MarkOverdueBorrowsUseCase;
import com.borrowservice.application.port.in.RemindApproachingDueDateUseCase; // <-- 1. Import new Use Case
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class OverdueBorrowScheduler {

    private final MarkOverdueBorrowsUseCase markOverdueBorrowsUseCase;
    private final RemindApproachingDueDateUseCase remindApproachingDueDateUseCase; // <-- 2. Declare it

    // 3. Inject it via the constructor
    public OverdueBorrowScheduler(
            MarkOverdueBorrowsUseCase markOverdueBorrowsUseCase,
            RemindApproachingDueDateUseCase remindApproachingDueDateUseCase) {
        this.markOverdueBorrowsUseCase = markOverdueBorrowsUseCase;
        this.remindApproachingDueDateUseCase = remindApproachingDueDateUseCase;
    }

    @Scheduled(cron = "0 1 0 * * *")
    public void scheduleOverdueCheck() {
        System.out.println("Running nightly overdue check job...");
        markOverdueBorrowsUseCase.markOverdue();
    }

    @Scheduled(cron = "0 0 9 * * *")
    public void scheduleDueSoonReminders() {
        System.out.println("Running daily approaching due date reminders...");
        remindApproachingDueDateUseCase.sendReminders(); // <-- 4. Call the new logic
    }
}