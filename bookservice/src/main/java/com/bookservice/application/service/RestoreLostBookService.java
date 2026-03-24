package com.bookservice.application.service;

import com.bookservice.application.port.in.RestoreLostBookUseCase;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

@Transactional
public class RestoreLostBookService implements RestoreLostBookUseCase {

    private final BookRepository repository;
    private final AuditMessagePort auditMessagePort;

    public RestoreLostBookService(BookRepository repository, AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public void restoreLost(String bookId) {
        // 1. Tìm cuốn sách trong hệ thống, ném ngoại lệ nếu không tồn tại ID
        Book book = repository.findById(bookId)
                .orElseThrow(() -> new BookNotFoundException("id", bookId));

        book.restoreLostCopy();

        // 3. Lưu các thay đổi vào cơ sở dữ liệu
        repository.save(book);

        // 4. Ghi nhật ký sự kiện hệ thống (Audit Log)
        auditMessagePort.sendBookEvent(
                "BOOK_COPY_RESTORED",
                bookId,
                "1 bản sao từng bị báo mất đã được tìm thấy và khôi phục vào kho sách."
        );
    }
}