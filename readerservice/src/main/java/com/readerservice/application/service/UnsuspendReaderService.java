package com.readerservice.application.service;

import com.readerservice.application.port.in.UnsuspendReaderUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.exception.ReaderNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

public class UnsuspendReaderService implements UnsuspendReaderUseCase {
    private static final Logger log = LoggerFactory.getLogger(UnsuspendReaderService.class);

    private final ReaderRepository readerRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;

    public UnsuspendReaderService(ReaderRepository readerRepository,
                                  AuditMessagePort auditMessagePort,
                                  NotificationPort notificationPort) {
        this.readerRepository = readerRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
    }

    @Override
    @Transactional
    public void unsuspend(String id) {
        log.info("Bắt đầu gỡ đình chỉ độc giả id={}", id);

        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new ReaderNotFoundException("id: " + id));

        reader.unsuspend();
        var saved = readerRepository.save(reader);

        auditMessagePort.sendReaderEvent(
                "READER_UNSUSPENDED",
                saved.getId(),
                "Độc giả đã được gỡ đình chỉ"
        );

        notificationPort.sendNotification(
                "READER_UNSUSPENDED",
                saved.getEmail().value(),
                Map.of("readerName", saved.getName())
        );

        log.info("Gỡ đình chỉ thành công cho độc giả id={}", saved.getId());
    }
}
