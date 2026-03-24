package com.bookservice.application.service;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.AddBookStockUseCase;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

/**
 * Dịch vụ xử lý việc nhập thêm số lượng sách vào kho.
 */
@Transactional
public class AddBookStockService implements AddBookStockUseCase {

    private final BookRepository repository;      // Kho lưu trữ dữ liệu sách
    private final AuditMessagePort auditMessagePort; // Cổng gửi thông báo nhật ký hệ thống

    public AddBookStockService(BookRepository repository, AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public BookDetailView add(String bookId, long amount) {
        // 1. Tìm kiếm sách theo ID, nếu không thấy sẽ ném ngoại lệ
        Book book = repository.findById(bookId)
                .orElseThrow(() -> new BookNotFoundException("id", bookId));

        // 2. Thực hiện logic nghiệp vụ trong tầng Domain (cộng dồn số lượng vào tồn kho)
        book.addInventory(amount);

        // 3. Lưu thông tin sách đã cập nhật vào cơ sở dữ liệu
        Book savedBook = repository.save(book);

        // 4. Ghi nhật ký hệ thống (Audit Log) để theo dõi biến động kho
        auditMessagePort.sendBookEvent(
                "BOOK_STOCK_ADDED",
                savedBook.getId(),
                "Đã thêm " + amount + " bản sao cho cuốn sách: " + savedBook.getTitle()
        );

        // 5. Trả về DTO hiển thị chi tiết sách sau khi cập nhật
        return BookDetailView.fromBook(savedBook);
    }
}