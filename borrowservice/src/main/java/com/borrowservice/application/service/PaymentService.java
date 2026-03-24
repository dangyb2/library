package com.borrowservice.application.service;

import com.borrowservice.application.port.in.PaymentUseCase;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.NotificationPort; // <-- 1. Nhập cổng thông báo
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Map; // <-- 2. Nhập Map để xử lý dữ liệu thông báo

import static com.borrowservice.application.util.CurrencyFormatter.formatVND; // <-- Sử dụng bộ định dạng tiền tệ VNĐ

/**
 * Dịch vụ xử lý thanh toán các khoản phí mượn sách hoặc tiền phạt.
 */
@Transactional
public class PaymentService extends BaseBorrowService implements PaymentUseCase { // <-- 3. Kế thừa BaseBorrowService

    private final BookBorrowRepository bookBorrowRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort; // <-- 4. Khai báo Port thông báo
    private final ReaderRegistryPort readerRegistryPort;

    public PaymentService(BookBorrowRepository bookBorrowRepository,
                          AuditMessagePort auditMessagePort,
                          NotificationPort notificationPort, // <-- 5. Tiêm (Inject) Port thông báo
                          BookCatalogPort bookCatalogPort,   // <-- 6. Tiêm BookCatalogPort (cho lớp cha)
                          ReaderRegistryPort readerRegistryPort) {
        super(bookCatalogPort, readerRegistryPort);
        this.bookBorrowRepository = bookBorrowRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public void pay(String borrowId) {
        // Tìm kiếm bản ghi mượn sách, ném lỗi nếu không tìm thấy ID
        Borrow borrow = bookBorrowRepository.findById(borrowId)
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(borrowId));

        // Lấy số tiền cần thanh toán (thường là tiền phạt hoặc phí thuê)
        java.math.BigDecimal amountPaid = borrow.getFine();

        // Thực hiện nghiệp vụ thanh toán trong Domain Model
        borrow.pay();

        // Lưu trạng thái mới vào cơ sở dữ liệu
        bookBorrowRepository.save(borrow);

        // Lấy thông tin hiển thị từ các Port liên quan
        String readerName = getReaderName(borrow.getReaderId());
        String bookTitle = getBookTitle(borrow.getBookId());
        String readerEmail = readerRegistryPort.getReaderEmail(borrow.getReaderId());

        // 1. Ghi nhật ký hệ thống (Dành cho quản trị viên đối soát)
        auditMessagePort.sendBorrowEvent(
                "PAYMENT",
                borrow.getBorrowId(),
                "Khoản thanh toán " + formatVND(amountPaid) + " đã được thực hiện thành công bởi " + readerName
        );

        // 2. Gửi biên lai qua Email (Dành cho độc giả)
        notificationPort.sendNotification(
                "PAYMENT", // Tên mẫu email biên lai thanh toán
                readerEmail,
                Map.of(
                        "readerName", readerName,
                        "bookTitle", bookTitle,
                        "amountPaid", formatVND(amountPaid),
                        "paymentDate", LocalDate.now().toString()
                )
        );
    }
}