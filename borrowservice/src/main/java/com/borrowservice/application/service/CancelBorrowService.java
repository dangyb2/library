package com.borrowservice.application.service;

import com.borrowservice.application.port.in.CancelBorrowUseCase;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.NotificationPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.exception.InvalidBorrowStateException;
import com.borrowservice.domain.model.Borrow;
import com.borrowservice.domain.model.Status;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Map;

/**
 * Dịch vụ xử lý việc hủy yêu cầu mượn sách.
 */
@Transactional
public class CancelBorrowService extends BaseBorrowService implements CancelBorrowUseCase {

    private final BookBorrowRepository repository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;
    private final ReaderRegistryPort readerRegistryPort;

    public CancelBorrowService(BookBorrowRepository repository,
                               BookCatalogPort bookCatalogPort,
                               ReaderRegistryPort readerRegistryPort,
                               AuditMessagePort auditMessagePort,
                               NotificationPort notificationPort) {
        super(bookCatalogPort, readerRegistryPort);
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public void cancelBorrow(String borrowId) {
        // Tìm kiếm bản ghi mượn sách, nếu không thấy sẽ ném lỗi
        Borrow borrow = repository.findById(borrowId)
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(borrowId));

        // 1. Kiểm tra tính lũy đẳng (Idempotency): Nếu đã hủy rồi thì không làm gì thêm.
        if (borrow.getStatus() == Status.CANCELLED) {
            return;
        }

        // 2. QUY TẮC MỚI: Chỉ cho phép hủy trong cùng ngày đã mượn
        if (!borrow.getBorrowDate().isEqual(LocalDate.now())) {
            throw new InvalidBorrowStateException("Yêu cầu mượn sách chỉ có thể được hủy trong cùng ngày mượn. Vui lòng sử dụng quy trình Trả sách để thay thế.");
        }

        // 3. Xử lý quy trình hủy
        borrow.cancel(); // Chuyển trạng thái trong Domain Model
        repository.save(borrow);

        // Khôi phục lại số lượng sách trong kho
        restoreBookStockSafely(borrow.getBookId());

        String bookTitle = getBookTitle(borrow.getBookId());
        String readerName = getReaderName(borrow.getReaderId());

        // 4. Gửi Nhật ký hệ thống (Audit Log)
        auditMessagePort.sendBorrowEvent(
                "BORROW_CANCELLED",
                borrow.getBorrowId(),
                readerName + " đã hủy yêu cầu mượn cuốn sách: " + bookTitle
        );

        // 5. Gửi Email xác nhận hủy thành công
        String readerEmail = readerRegistryPort.getReaderEmail(borrow.getReaderId());

        notificationPort.sendNotification(
                "CANCEL_SUCCESS",
                readerEmail,
                Map.of(
                        "readerName", readerName,
                        "bookTitle", bookTitle,
                        "cancelDate", LocalDate.now().toString()
                )
        );
    }
}