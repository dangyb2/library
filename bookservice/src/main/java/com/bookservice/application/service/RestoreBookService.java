package com.bookservice.application.service;

import com.bookservice.application.port.in.RestoreBookUseCase;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

@Transactional
public class RestoreBookService implements RestoreBookUseCase {

    private final BookRepository bookRepository;
    private final AuditMessagePort auditMessagePort;

    public RestoreBookService(BookRepository bookRepository, AuditMessagePort auditMessagePort) {
        this.bookRepository = bookRepository;
        this.auditMessagePort = auditMessagePort;
    }
    @Override
    public void restore(String bookId) {
        // 1. Gọi repository để khôi phục sách (thường là đổi trạng thái 'deleted' thành 'active')
        int soDongCapNhat = bookRepository.restoreBookById(bookId);

        // 2. Nếu không có dòng nào được cập nhật, nghĩa là không tìm thấy bản ghi đã xóa khớp với ID này
        if (soDongCapNhat == 0) {
            throw new BookNotFoundException("Không tìm thấy sách đã xóa với mã (ID): " + bookId);
        }

        // 3. Tìm lại sách đã được khôi phục để lấy thông tin chi tiết
        Book restoredBook = bookRepository.findById(bookId)
                .orElseThrow(() -> new BookNotFoundException(bookId));

        // 4. Ghi nhật ký hệ thống (Audit Log)
        // PHẦN ĐÃ SỬA: Thay đổi từ 'savedBook.getId()' thành 'restoredBook.getId()' để đảm bảo tham chiếu đúng
        auditMessagePort.sendBookEvent(
                "BOOK_RESTORED",
                restoredBook.getId(),
                "Sách đã được khôi phục thành công từ kho lưu trữ: " + restoredBook.getTitle()
        );
    }
}