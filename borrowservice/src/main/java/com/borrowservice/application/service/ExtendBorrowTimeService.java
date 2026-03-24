package com.borrowservice.application.service;

import com.borrowservice.application.dto.ExtendBorrowResultView;
import com.borrowservice.application.port.in.ExtendBorrowTimeUseCase;
import com.borrowservice.application.port.in.command.ExtendBorrowCommand;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.NotificationPort; // <-- 1. Nhập cổng thông báo
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map; // <-- 2. Nhập Map để chứa dữ liệu email

/**
 * Dịch vụ xử lý việc gia hạn thời gian mượn sách.
 */
@Transactional
public class ExtendBorrowTimeService extends BaseBorrowService implements ExtendBorrowTimeUseCase {

    private final BookBorrowRepository bookBorrowRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;
    private final ReaderRegistryPort readerRegistryPort;

    public ExtendBorrowTimeService(BookBorrowRepository bookBorrowRepository,
                                   AuditMessagePort auditMessagePort,
                                   NotificationPort notificationPort,
                                   BookCatalogPort bookCatalogPort,
                                   ReaderRegistryPort readerRegistryPort) {
        super(bookCatalogPort, readerRegistryPort); // Gọi constructor của lớp cha BaseBorrowService
        this.bookBorrowRepository = bookBorrowRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public ExtendBorrowResultView extend(ExtendBorrowCommand command) {

        // Tìm kiếm bản ghi mượn sách, ném lỗi nếu không tồn tại
        Borrow borrow = bookBorrowRepository.findById(command.borrowId())
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(command.borrowId()));

        // Thực hiện logic gia hạn trong Domain Model (cập nhật ngày hẹn trả mới)
        borrow.extendBorrowTime(command.newDueDate());

        // Lưu thay đổi vào cơ sở dữ liệu
        bookBorrowRepository.save(borrow);

        // 1. Ghi Nhật ký hệ thống (Dành cho quản trị viên)
        auditMessagePort.sendBorrowEvent(
                "BORROW_EXTENDED",
                borrow.getBorrowId(),
                "Yêu cầu mượn " + borrow.getBorrowId() + " đã được gia hạn đến ngày " + borrow.getDueDate()
        );

        // 2. Lấy thông tin cần thiết để gửi Email
        String readerEmail = readerRegistryPort.getReaderEmail(borrow.getReaderId());
        String readerName = getReaderName(borrow.getReaderId()); // Sử dụng phương thức từ BaseBorrowService
        String bookTitle = getBookTitle(borrow.getBookId());    // Sử dụng phương thức từ BaseBorrowService

        // 3. Gửi thông báo Email cho độc giả
        notificationPort.sendNotification(
                "BORROWING_EXTENDED", // Tên mẫu email (Template)
                readerEmail,
                Map.of(
                        "readerName", readerName,
                        "bookTitle", bookTitle,
                        "dueDate", borrow.getDueDate().toString()
                )
        );

        // Trả về kết quả gia hạn thành công
        return new ExtendBorrowResultView(
                borrow.getBorrowId(),
                borrow.getDueDate()
        );
    }
}