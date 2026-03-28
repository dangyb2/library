package com.readerservice.application.service;

import com.readerservice.application.port.in.DeleteReaderUseCase;
import com.readerservice.application.port.out.AuditMessagePort;
import com.readerservice.application.port.out.CheckReaderBorrowStatusPort; // <-- Thêm Port mới
import com.readerservice.application.port.out.NotificationPort;
import com.readerservice.application.port.out.ReaderRepository;
import com.readerservice.domain.exception.ReaderHasActiveBorrowsException; // <-- Thêm Exception
import com.readerservice.domain.exception.ReaderNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

public class DeleteReaderService implements DeleteReaderUseCase {
    private static final Logger log = LoggerFactory.getLogger(DeleteReaderService.class);

    private final ReaderRepository readerRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;
    private final CheckReaderBorrowStatusPort borrowStatusPort;

    public DeleteReaderService(ReaderRepository readerRepository,
                               AuditMessagePort auditMessagePort,
                               NotificationPort notificationPort,
                               CheckReaderBorrowStatusPort borrowStatusPort) {
        this.readerRepository = readerRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
        this.borrowStatusPort = borrowStatusPort;
    }

    @Override
    @Transactional
    public void delete(String id) {
        log.info("Bắt đầu xóa độc giả id={}", id);

        var reader = readerRepository.findById(id)
                .orElseThrow(() -> new ReaderNotFoundException("id: " + id));

        if (borrowStatusPort.hasActiveBorrowsOrFines(id)) {
            log.warn("Từ chối xóa: Độc giả {} đang có khoản vay/phạt", id);
            throw new ReaderHasActiveBorrowsException(reader.getName());
        }

        readerRepository.deleteById(reader.getId());

        auditMessagePort.sendReaderEvent(
                "READER_DELETED",
                reader.getId(),
                "Đã xóa độc giả " + reader.getName()
        );

        notificationPort.sendNotification(
                "READER_DELETED",
                reader.getEmail().value(),
                Map.of(
                        "readerName", reader.getName(),
                        "deletedAt", LocalDateTime.now().toString()
                )
        );
        log.info("Xóa độc giả thành công id={}", reader.getId());
    }
}