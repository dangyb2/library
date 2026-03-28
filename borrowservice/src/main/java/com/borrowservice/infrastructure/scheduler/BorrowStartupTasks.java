package com.borrowservice.infrastructure.scheduler;

import com.borrowservice.application.port.in.MarkOverdueBorrowsUseCase;
import com.borrowservice.application.port.in.RemindApproachingDueDateUseCase;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class BorrowStartupTasks implements CommandLineRunner {

    private final MarkOverdueBorrowsUseCase markOverdueBorrowsUseCase;
    private final RemindApproachingDueDateUseCase remindApproachingDueDateUseCase;

    // Inject your use cases via constructor
    public BorrowStartupTasks(
            MarkOverdueBorrowsUseCase markOverdueBorrowsUseCase,
            RemindApproachingDueDateUseCase remindApproachingDueDateUseCase) {
        this.markOverdueBorrowsUseCase = markOverdueBorrowsUseCase;
        this.remindApproachingDueDateUseCase = remindApproachingDueDateUseCase;
    }

    @Override
    public void run(String... args) {
        System.out.println("🚀 Borrow Service started! Running initial background tasks...");

        try {
            // 1. Mark any books that became overdue while the service was offline
            markOverdueBorrowsUseCase.markOverdue();
            System.out.println("✅ Initial overdue check completed.");

            // 2. Send out reminders for books due soon
            remindApproachingDueDateUseCase.sendReminders();
            System.out.println("✅ Initial due date reminders sent.");

        } catch (Exception e) {
            System.err.println("❌ Error running startup tasks: " + e.getMessage());
        }
    }
}