package com.borrowservice.application.service;

import com.borrowservice.application.dto.ReturnedBorrowView;
import com.borrowservice.application.port.in.ReturnBookUseCase;
import com.borrowservice.application.port.in.command.ReturnBookCommand;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.NotificationPort; // <-- 1. Nhập cổng thông báo
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map; // <-- 2. Nhập Map để xử lý dữ liệu email

import static com.borrowservice.application.util.CurrencyFormatter.formatVND; // <-- Sử dụng bộ định dạng VNĐ

/**
 * Dịch vụ xử lý quy trình trả sách và kết thúc phiên mượn.
 */
@Transactional
public class ReturnBookService extends BaseBorrowService implements ReturnBookUseCase {

    private final BookBorrowRepository bookBorrowRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort; // <-- 3. Khai báo Port thông báo
    private final ReaderRegistryPort readerRegistryPort; // <-- Lưu cục bộ để lấy email độc giả

    public ReturnBookService(BookBorrowRepository bookBorrowRepository,
                             BookCatalogPort bookCatalogPort,
                             ReaderRegistryPort readerRegistryPort,
                             AuditMessagePort auditMessagePort,
                             NotificationPort notificationPort) { // <-- 4. Tiêm (Inject) Port
        super(bookCatalogPort, readerRegistryPort);
        this.bookBorrowRepository = bookBorrowRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort; // <-- Gán giá trị
        this.readerRegistryPort = readerRegistryPort; // <-- Gán giá trị
    }

    @Override
    public ReturnedBorrowView returnBook(ReturnBookCommand command) {
        // Tìm bản ghi mượn sách, ném lỗi nếu không tồn tại ID
        Borrow borrow = bookBorrowRepository.findById(command.borrowId())
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(command.borrowId()));

        // Thực thi nghiệp vụ trả sách trong Domain (cập nhật ngày trả, tình trạng và tính phí/phạt)
        borrow.returnBook(command.returnDate(), command.conditionReturn());
        Borrow savedBorrow = bookBorrowRepository.save(borrow);

        // Khôi phục số lượng sách vào kho một cách an toàn
        restoreBookStockSafely(savedBorrow.getBookId());

        // Trích xuất các khoản chi phí
        BigDecimal rentalFee = savedBorrow.getPrice();
        BigDecimal fineAmount = savedBorrow.getFine();
        BigDecimal totalToPay = rentalFee.add(fineAmount);

        // Lấy thông tin hiển thị (từ BaseBorrowService)
        String bookTitle = getBookTitle(savedBorrow.getBookId());
        String readerName = getReaderName(savedBorrow.getReaderId());

        // Ghi nhật ký hệ thống (Audit Log)
        auditMessagePort.sendBorrowEvent(
                "BOOK_RETURNED",
                borrow.getBorrowId(),
                String.format("%s đã trả sách: %s. Giá thuê: %s, Tiền phạt: %s. TỔNG THANH TOÁN: %s",
                        readerName, bookTitle, formatVND(rentalFee), formatVND(fineAmount), formatVND(totalToPay))
        );

        // 5. KÍCH HOẠT THÔNG BÁO EMAIL XÁC NHẬN TRẢ SÁCH!
        String readerEmail = readerRegistryPort.getReaderEmail(savedBorrow.getReaderId());

        notificationPort.sendNotification(
                "BOOK_RETURNED", // Tên mẫu email trong dịch vụ thông báo
                readerEmail,
                Map.of(
                        "readerName", readerName,
                        "bookTitle", bookTitle,
                        "returnedAt", savedBorrow.getReturnDate().toString(),
                        // Cung cấp thêm dữ liệu chi phí cho mẫu email trong tương lai:
                        "rentalFee", formatVND(rentalFee),
                        "fineAmount", formatVND(fineAmount),
                        "totalToPay", formatVND(totalToPay)
                )
        );

        // Trả về DTO hiển thị kết quả trả sách thành công
        return new ReturnedBorrowView(
                savedBorrow.getBorrowId(),
                savedBorrow.getBookId(),
                savedBorrow.getReturnDate(),
                savedBorrow.getConditionReturn(),
                savedBorrow.getStatus(),
                fineAmount,
                rentalFee
        );
    }
}