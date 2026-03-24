package com.bookservice.application.service;

import com.bookservice.application.port.in.MarkBookLostUseCase;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

/**
 * Dịch vụ xử lý việc đánh dấu một bản sao sách đã bị mất.
 */
@Transactional
public class MarkBookLostService implements MarkBookLostUseCase {

    private final BookRepository repository;      // Kho lưu trữ sách
    private final AuditMessagePort auditMessagePort; // Cổng gửi nhật ký hệ thống

    public MarkBookLostService(BookRepository repository, AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public void markLost(String bookId) {
        // 1. Tìm cuốn sách trong hệ thống, ném lỗi nếu không tồn tại ID
        Book book = repository.findById(bookId)
                .orElseThrow(() -> new BookNotFoundException("id", bookId));

        book.markCopyAsLostByReader();

        // 3. Lưu cập nhật thay đổi vào cơ sở dữ liệu
        repository.save(book);

        // 4. Ghi nhật ký sự kiện hệ thống (Audit Log)
        auditMessagePort.sendBookEvent(
                "BOOK_COPY_LOST",
                bookId,
                "1 bản sao đã được độc giả báo mất."
        );
    }
}