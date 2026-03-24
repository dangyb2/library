package com.bookservice.application.service;

import com.bookservice.application.dto.TotalStockDecreaseView;
import com.bookservice.application.port.in.DecreaseTotalStockUseCase;
import com.bookservice.application.port.in.command.DecreaseTotalStockCommand;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.exception.InvalidBookDataException;
import com.bookservice.domain.model.Book;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

/**
 * Dịch vụ xử lý việc giảm tổng số lượng sách trong kho (do hư hỏng, thanh lý, v.v.).
 */
@Transactional
public class DecreaseTotalStockService implements DecreaseTotalStockUseCase {

    private static final Logger log = LoggerFactory.getLogger(DecreaseTotalStockService.class);

    private final BookRepository repository;      // Kho lưu trữ sách
    private final AuditMessagePort auditMessagePort; // Cổng gửi nhật ký hệ thống

    public DecreaseTotalStockService(BookRepository repository, AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public TotalStockDecreaseView decrease(String bookId, DecreaseTotalStockCommand command) {
        // 1. Kiểm tra tính hợp lệ của số lượng (phải lớn hơn 0)
        if (command.amount() <= 0) {
            throw new InvalidBookDataException("Số lượng cần giảm phải lớn hơn 0");
        }

        // 2. Tìm kiếm sách trong hệ thống, ném lỗi nếu không tồn tại
        Book book = repository.findById(bookId)
                .orElseThrow(() -> new BookNotFoundException("id", bookId));

        // 3. Thực hiện logic nghiệp vụ: Loại bỏ bản sao sách khỏi tổng kho
        // Phương thức này ở tầng Domain thường sẽ kiểm tra xem số lượng giảm có vượt quá tồn kho không.
        book.removeCopies(command.amount());

        // 4. Lưu trạng thái sách đã cập nhật
        Book savedBook = repository.save(book);

        // 5. Ghi Log nội bộ cho lập trình viên
        log.info("Đã xóa {} bản sao của sách '{}'. Lý do: {}",
                command.amount(), bookId, command.reason());

        // 6. Ghi nhật ký sự kiện hệ thống (Audit Log) để quản trị viên theo dõi
        auditMessagePort.sendBookEvent(
                "BOOK_STOCK_REMOVED",
                savedBook.getId(),
                "Đã xóa " + command.amount() + " bản sao. Lý do: " + command.reason()
        );

        // 7. Trả về thông tin chi tiết về việc giảm kho
        return TotalStockDecreaseView.fromBook(savedBook, command.amount(), command.reason());
    }
}