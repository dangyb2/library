package com.readerservice.application.service;

import com.readerservice.domain.exception.ReaderAlreadyExistsException;
import com.readerservice.application.port.in.CreateReaderUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.model.Email;
import com.readerservice.domain.model.PhoneNumber;
import com.readerservice.domain.model.Reader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

public class CreateReaderService implements CreateReaderUseCase {
    private static final Logger log = LoggerFactory.getLogger(CreateReaderService.class);

    private final ReaderRepository readerRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;

    public CreateReaderService(ReaderRepository readerRepository,
                               AuditMessagePort auditMessagePort,
                               NotificationPort notificationPort) {
        this.readerRepository = readerRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
    }
    @Override
    @Transactional

    public String create(String name, String email, String phone, LocalDate expireAt) {
        log.info("Bắt đầu tạo độc giả mới với email: {}", email);

        Email emailValue = new Email(email);
        PhoneNumber phoneValue = new PhoneNumber(phone);

        if (readerRepository.findByEmail(emailValue).isPresent()) {
            throw ReaderAlreadyExistsException.forEmail(emailValue.value());
        }
        if (readerRepository.findByPhone(phoneValue).isPresent()) {
            throw ReaderAlreadyExistsException.forPhone(phoneValue.value());
        }

        String newReaderId = "READER-" + UUID.randomUUID();

        Reader reader = new Reader(
                newReaderId,
                name,
                emailValue,
                phoneValue,
                expireAt
        );

        Reader saved = readerRepository.save(reader);

        auditMessagePort.sendReaderEvent(
                "READER_CREATED",
                saved.getId(),
                "Đã tạo mới độc giả " + saved.getName()
        );

        notificationPort.sendNotification(
                "READER_CREATED",
                saved.getEmail().value(),
                Map.of(
                        "readerName", saved.getName(),
                        "readerId", saved.getId()
                )
        );

        log.info("Tạo độc giả thành công. readerId={}", saved.getId());
        return saved.getId();
    }
}
