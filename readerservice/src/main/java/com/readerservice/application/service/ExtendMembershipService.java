package com.readerservice.application.service;

import com.readerservice.application.port.in.ExtendMembershipUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.exception.ReaderNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Map;

public class ExtendMembershipService implements ExtendMembershipUseCase {
    private static final Logger log = LoggerFactory.getLogger(ExtendMembershipService.class);

    private final ReaderRepository readerRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;

    public ExtendMembershipService(ReaderRepository readerRepository,
                                   AuditMessagePort auditMessagePort,
                                   NotificationPort notificationPort) {
        this.readerRepository = readerRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
    }

    @Override
    @Transactional
    public void extend(String id, LocalDate newDate) {
        log.info("Bắt đầu gia hạn thẻ cho độc giả id={}", id);

        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new ReaderNotFoundException("id: " + id));

        reader.extendMembership(newDate);
        var saved = readerRepository.save(reader);

        auditMessagePort.sendReaderEvent(
                "READER_MEMBERSHIP_EXTENDED",
                saved.getId(),
                "Đã gia hạn thẻ thành viên đến ngày " + saved.getMembershipExpireAt()
        );

        notificationPort.sendNotification(
                "READER_UPDATED",
                saved.getEmail().value(),
                Map.of(
                        "readerName", saved.getName(),
                        "updatedAt", LocalDate.now().toString()
                )
        );

        log.info("Gia hạn thẻ thành công cho độc giả id={}, hạn mới={}", saved.getId(), saved.getMembershipExpireAt());
    }
}
