package com.readerservice.application.service;

import com.readerservice.application.port.in.NotifyMembershipStatusUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Reader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public class NotifyMembershipStatusService implements NotifyMembershipStatusUseCase {
    private static final Logger log = LoggerFactory.getLogger(NotifyMembershipStatusService.class);

    private final ReaderRepository readerRepository;
    private final NotificationPort notificationPort;
    private final AuditMessagePort auditMessagePort;
    private final int expiringBeforeDays;

    public NotifyMembershipStatusService(ReaderRepository readerRepository,
                                         NotificationPort notificationPort,
                                         AuditMessagePort auditMessagePort,
                                         int expiringBeforeDays) {
        this.readerRepository = readerRepository;
        this.notificationPort = notificationPort;
        this.auditMessagePort = auditMessagePort;
        if (expiringBeforeDays < 1) {
            throw new IllegalArgumentException("expiringBeforeDays must be at least 1, got: " + expiringBeforeDays);
        }
        this.expiringBeforeDays = expiringBeforeDays;
    }

    @Override
    @Transactional(readOnly = true)
    public void notifyMembershipStatus() {
        LocalDate today = LocalDate.now();
        LocalDate expiringDate = today.plusDays(expiringBeforeDays);
        LocalDate justExpiredDate = today.minusDays(1);

        List<Reader> expiringReaders = readerRepository.findByMembershipExpireAt(expiringDate);
        List<Reader> expiredReaders  = readerRepository.findByMembershipExpireAt(justExpiredDate);

        int expiringCount = 0;
        int expiredCount = 0;

        for (Reader reader : expiringReaders) {
            try {
                sendExpiringNotification(reader);
                expiringCount++;
            } catch (Exception ex) {
                log.error("Failed to notify expiring reader id={}: {}", reader.getId(), ex.getMessage());
            }
        }

        for (Reader reader : expiredReaders) {
            try {
                sendExpiredNotification(reader);
                expiredCount++;
            } catch (Exception ex) {
                log.error("Failed to notify expired reader id={}: {}", reader.getId(), ex.getMessage());
            }
        }

        log.info("Job nhắc hạn thành viên hoàn tất. Sắp hết hạn={}, Đã hết hạn={}", expiringCount, expiredCount);
    }

    private void sendExpiringNotification(Reader reader) {
        notificationPort.sendNotification(
                "MEMBERSHIP_EXPIRING",
                reader.getEmail().value(),
                Map.of(
                        "readerName", reader.getName(),
                        "membershipEndDate", reader.getMembershipExpireAt().toString()
                )
        );

        auditMessagePort.sendReaderEvent(
                "MEMBERSHIP_EXPIRING",
                reader.getId(),
                "Thẻ thành viên sắp hết hạn vào ngày " + reader.getMembershipExpireAt()
        );

        log.info("Đã gửi thông báo sắp hết hạn cho độc giả id={}", reader.getId());
    }

    private void sendExpiredNotification(Reader reader) {
        notificationPort.sendNotification(
                "MEMBERSHIP_EXPIRED",
                reader.getEmail().value(),
                Map.of(
                        "readerName", reader.getName(),
                        "membershipEndDate", reader.getMembershipExpireAt().toString()
                )
        );

        auditMessagePort.sendReaderEvent(
                "MEMBERSHIP_EXPIRED",
                reader.getId(),
                "Thẻ thành viên đã hết hạn từ ngày " + reader.getMembershipExpireAt()
        );

        log.info("Đã gửi thông báo hết hạn cho độc giả id={}", reader.getId());
    }
}
