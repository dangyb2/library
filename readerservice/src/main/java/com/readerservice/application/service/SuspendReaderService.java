package com.readerservice.application.service;

import com.readerservice.application.port.in.SuspendReaderUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.exception.ReaderNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

public class SuspendReaderService implements SuspendReaderUseCase {
    private static final Logger log = LoggerFactory.getLogger(SuspendReaderService.class);

    private final ReaderRepository readerRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;

    public SuspendReaderService(ReaderRepository readerRepository,
                                AuditMessagePort auditMessagePort,
                                NotificationPort notificationPort) {
        this.readerRepository = readerRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
    }

    @Override
    @Transactional
    public void suspend(String id, String reason) {
        log.info("Bắt đầu đình chỉ độc giả id={}", id);

        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new ReaderNotFoundException("id: " + id));

        reader.suspend(reason);
        var saved = readerRepository.save(reader);

        auditMessagePort.sendReaderEvent(
                "READER_SUSPENDED",
                saved.getId(),
                "Độc giả bị đình chỉ. Lý do: " + saved.getSuspendReason()
        );

        notificationPort.sendNotification(
                "READER_SUSPENDED",
                saved.getEmail().value(),
                Map.of(
                        "readerName", saved.getName(),
                        "reason", saved.getSuspendReason()
                )
        );

        log.info("Đình chỉ độc giả thành công id={}", saved.getId());
    }
}
