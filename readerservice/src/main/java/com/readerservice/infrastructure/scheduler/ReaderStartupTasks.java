package com.readerservice.infrastructure.scheduler;

import com.readerservice.application.port.in.NotifyMembershipStatusUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class ReaderStartupTasks implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(ReaderStartupTasks.class);
    private final NotifyMembershipStatusUseCase notifyMembershipStatusUseCase;

    public ReaderStartupTasks(NotifyMembershipStatusUseCase notifyMembershipStatusUseCase) {
        this.notifyMembershipStatusUseCase = notifyMembershipStatusUseCase;
    }

    @Override
    public void run(String... args) {
        log.info("🚀 Reader Service started! Running initial membership status check...");

        try {
            // Check for memberships expiring soon or already expired while service was down
            notifyMembershipStatusUseCase.notifyMembershipStatus();
            log.info("✅ Initial membership status check completed successfully.");
        } catch (Exception e) {
            log.error("❌ Error running Reader startup tasks: {}", e.getMessage(), e);
        }
    }
}