package com.readerservice.application.service;

import com.readerservice.application.dto.ReaderView;
import com.readerservice.application.port.in.UpdateReaderUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.exception.ReaderAlreadyExistsException;
import com.readerservice.domain.exception.ReaderNotFoundException;
import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

public class UpdateReaderService implements UpdateReaderUseCase {
    private static final Logger log = LoggerFactory.getLogger(UpdateReaderService.class);

    private final ReaderRepository readerRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;

    public UpdateReaderService(ReaderRepository readerRepository,
                               AuditMessagePort auditMessagePort,
                               NotificationPort notificationPort) {
        this.readerRepository = readerRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
    }

    @Override
@Transactional
    public ReaderView update(String id, String name, String email, String phone) {
        log.info("Bắt đầu cập nhật độc giả id={}", id);

        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new ReaderNotFoundException("id: " + id));

        Email emailValue = new Email(email);
        PhoneNumber phoneValue = new PhoneNumber(phone);

        readerRepository.findByEmail(emailValue)
                .filter(existing -> !existing.getId().equals(id))
                .ifPresent(_ -> {
                    throw ReaderAlreadyExistsException.forEmail(emailValue.value());
                });

        readerRepository.findByPhone(phoneValue)
                .filter(existing -> !existing.getId().equals(id))
                .ifPresent(_ -> {
                    throw ReaderAlreadyExistsException.forPhone(phoneValue.value());
                });

        // FIXED: Now only passes the 3 profile arguments
        reader.updateProfile(name, emailValue, phoneValue);

        var saved = readerRepository.save(reader);

        auditMessagePort.sendReaderEvent(
                "READER_UPDATED",
                saved.getId(),
                "Đã cập nhật thông tin độc giả " + saved.getName()
        );

        notificationPort.sendNotification(
                "READER_UPDATED",
                saved.getEmail().value(),
                Map.of(
                        "readerName", saved.getName(),
                        "updatedAt", LocalDateTime.now().toString()
                )
        );

        log.info("Cập nhật độc giả thành công id={}", saved.getId());
        return ReaderView.from(saved);
    }
}