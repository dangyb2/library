package com.bookservice.application.service;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.CheckoutBookUseCase;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

/**
 * Dịch vụ xử lý việc mượn sách (Checkout) từ kho.
 * Đảm bảo số lượng tồn kho được cập nhật chính xác.
 */
@Transactional
public class CheckoutBookService implements CheckoutBookUseCase {

    private final BookRepository repository;      // Kho lưu trữ sách
    private final AuditMessagePort auditMessagePort; // Cổng gửi nhật ký hệ thống

    public CheckoutBookService(BookRepository repository,
                               AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public BookDetailView checkout(String bookId) {
        // 1. Tìm cuốn sách trong cơ sở dữ liệu, nếu không thấy sẽ báo lỗi
        Book book = repository.findById(bookId)
                .orElseThrow(() -> new BookNotFoundException("id", bookId));

        // 2. Thực hiện logic nghiệp vụ: Giảm số lượng sách sẵn có đi 1
        // Lưu ý: Logic kiểm tra sách còn hay hết thường nằm bên trong phương thức này ở tầng Domain
        book.decreaseAvailableStock(1L);

        // 3. Lưu trạng thái mới của cuốn sách
        Book savedBook = repository.save(book);

        // 4. Ghi nhật ký sự kiện hệ thống
        auditMessagePort.sendBookEvent(
                "BOOK_CHECKED_OUT",
                savedBook.getId(),
                "Sách đã được mượn: " + savedBook.getTitle()
        );

        // 5. Trả về thông tin chi tiết của cuốn sách dưới dạng DTO
        return BookDetailView.fromBook(savedBook);
    }
}