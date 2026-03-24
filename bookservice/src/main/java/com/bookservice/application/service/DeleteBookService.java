package com.bookservice.application.service;

import com.bookservice.application.port.in.DeleteBookUseCase;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookCurrentlyBorrowedException;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

/**
 * Dịch vụ xử lý việc xóa hoàn toàn một đầu sách khỏi hệ thống.
 */
@Transactional
public class DeleteBookService implements DeleteBookUseCase {

    private final BookRepository repository;      // Kho lưu trữ sách
    private final AuditMessagePort auditMessagePort; // Cổng gửi nhật ký hệ thống

    public DeleteBookService(BookRepository repository, AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public void deleteBook(String bookId) {
        // 1. Tìm cuốn sách trong hệ thống, nếu không thấy sẽ ném lỗi "Không tìm thấy sách"
        Book book = repository.findById(bookId)
                .orElseThrow(() -> new BookNotFoundException(bookId));

        // 2. Quy tắc nghiệp vụ: Không xóa sách khi vẫn còn người đang mượn!
        // Kiểm tra: Nếu số lượng sẵn có (Available Stock) không bằng tổng số lượng (Total Stock),
        // nghĩa là có ít nhất một cuốn đang nằm trong tay độc giả.
        if (!book.getAvailableStock().equals(book.getTotalStock())) {
            throw new BookCurrentlyBorrowedException(bookId);
        }

        // 3. Thực hiện xóa sách khỏi cơ sở dữ liệu
        repository.deleteById(bookId);

        // 4. Ghi nhật ký sự kiện hệ thống (Audit Log)
        auditMessagePort.sendDeleteBookEvent(
                "BOOK_DELETED",
                bookId,
                "Đã xóa cuốn sách có tiêu đề: " + book.getTitle()
        );
    }
}