package com.borrowservice.application.service;

import com.borrowservice.application.port.in.UndoCancelBorrowUseCase;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.exception.BookNotAvailableException;
import com.borrowservice.domain.exception.InvalidBorrowStateException;
import com.borrowservice.domain.model.Borrow;
import com.borrowservice.domain.model.Status;
import org.springframework.transaction.annotation.Transactional;

/**
 * Dịch vụ xử lý việc hoàn tác (undo) một yêu cầu mượn sách đã bị hủy.
 */
@Transactional
public class UndoCancelBorrowService implements UndoCancelBorrowUseCase {

    private final BookBorrowRepository repository;
    private final BookCatalogPort bookCatalogPort;
    private final AuditMessagePort auditMessagePort;

    public UndoCancelBorrowService(BookBorrowRepository repository,
                                   BookCatalogPort bookCatalogPort,
                                   AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.bookCatalogPort = bookCatalogPort;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public void undoCancelBorrow(String borrowId) {
        // Tìm kiếm bản ghi mượn sách, ném lỗi nếu không tồn tại
        Borrow borrow = repository.findById(borrowId)
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(borrowId));

        // Kiểm tra trạng thái: Chỉ có thể hoàn tác nếu bản ghi đang ở trạng thái CANCELLED (Đã hủy)
        if (borrow.getStatus() != Status.CANCELLED) {
            throw new InvalidBorrowStateException(borrowId, borrow.getStatus(), "HOÀN_TÁC_HỦY");
        }

        // 1. Kiểm tra xem sách có còn sẵn trong kho để mượn lại không!
        boolean isAvailable = bookCatalogPort.isBookAvailable(borrow.getBookId());
        if (!isAvailable) {
            throw new BookNotAvailableException(borrow.getBookId());
        }

        // 3. Thực hiện logic nghiệp vụ trong tầng Domain (chuyển trạng thái về BORROWED)
        borrow.undoCancel();

        // Lưu thay đổi vào cơ sở dữ liệu
        repository.save(borrow);

        // 5. Đặt lại (giảm) số lượng sách trong kho
        // Sử dụng khối try-catch để đảm bảo tính nhất quán với dịch vụ mượn sách chính
        try {
            bookCatalogPort.decreaseBookStock(borrow.getBookId());
        } catch (Exception e) {
            throw new BookNotAvailableException(borrow.getBookId() + " (Cập nhật kho hàng thất bại)");
        }

        // 6. Ghi nhật ký hệ thống (Audit Log)
        auditMessagePort.sendBorrowEvent(
                "BORROW_UNDO_CANCELLED",
                borrow.getBorrowId(),
                "Lệnh hủy cho bản ghi mượn " + borrowId + " đã được hoàn tác."
        );
    }
}