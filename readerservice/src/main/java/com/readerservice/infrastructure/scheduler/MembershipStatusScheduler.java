package com.readerservice.infrastructure.scheduler;

import com.readerservice.application.port.in.NotifyMembershipStatusUseCase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class MembershipStatusScheduler {
    private static final Logger log = LoggerFactory.getLogger(MembershipStatusScheduler.class);

    private final NotifyMembershipStatusUseCase notifyMembershipStatusUseCase;

    public MembershipStatusScheduler(NotifyMembershipStatusUseCase notifyMembershipStatusUseCase) {
        this.notifyMembershipStatusUseCase = notifyMembershipStatusUseCase;
    }

    @Scheduled(cron = "0 1 0 * * *")
    public void scheduleMembershipReminder() {
        log.info("Bắt đầu job kiểm tra hạn thành viên");
        try {
            notifyMembershipStatusUseCase.notifyMembershipStatus();
            log.info("Kết thúc job kiểm tra hạn thành viên");
        } catch (Exception ex) {
            log.error("Job kiểm tra hạn thành viên thất bại: {}", ex.getMessage(), ex);
        }
    }
}
