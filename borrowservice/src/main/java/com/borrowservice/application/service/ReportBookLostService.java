package com.borrowservice.application.service;

import com.borrowservice.application.dto.LostReportResult;
import com.borrowservice.application.port.in.ReportBookLostUseCase;
import com.borrowservice.application.port.in.command.ReportLostCommand;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.NotificationPort; // <-- 1. Nhập cổng thông báo
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map; // <-- 2. Nhập Map để chứa dữ liệu thông báo

import static com.borrowservice.application.util.CurrencyFormatter.formatVND;

/**
 * Dịch vụ xử lý nghiệp vụ khi độc giả báo mất sách.
 */
@Transactional
public class ReportBookLostService extends BaseBorrowService implements ReportBookLostUseCase {

    private final BookBorrowRepository bookBorrowRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort; // <-- 3. Khai báo Port thông báo
    private final ReaderRegistryPort readerRegistryPort; // <-- Lưu cục bộ để lấy email độc giả

    public ReportBookLostService(BookBorrowRepository bookBorrowRepository,
                                 AuditMessagePort auditMessagePort,
                                 NotificationPort notificationPort, // <-- 4. Tiêm (Inject) Port thông báo
                                 BookCatalogPort bookCatalogPort,
                                 ReaderRegistryPort readerRegistryPort) {
        super(bookCatalogPort, readerRegistryPort);
        this.bookBorrowRepository = bookBorrowRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort; // <-- Gán giá trị
        this.readerRegistryPort = readerRegistryPort; // <-- Gán giá trị
    }

    @Override
    public LostReportResult report(ReportLostCommand command) {
        // 1. Tìm bản ghi mượn sách, ném lỗi nếu không tồn tại
        Borrow borrow = bookBorrowRepository.findById(command.borrowId())
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(command.borrowId()));

        // 2. Thực thi logic nghiệp vụ tại tầng Domain (tính toán tiền phạt và đổi trạng thái thành LOST)
        borrow.reportLost(command.reportDate());

        // 3. Lưu các thay đổi vào Cơ sở dữ liệu
        bookBorrowRepository.save(borrow);

        // 4. Cập nhật trạng thái sách trong Danh mục (Đánh dấu bản sao này đã mất)
        bookCatalogPort.markCopyAsLost(borrow.getBookId());

        // 5. Trích xuất dữ liệu đã tính toán để xây dựng DTO kết quả
        BigDecimal rentalFee = borrow.getPrice();
        BigDecimal fineAmount = borrow.getFine();
        BigDecimal totalAmount = rentalFee.add(fineAmount);

        LostReportResult result = new LostReportResult(rentalFee, fineAmount, totalAmount);

        // 6. Lấy tên sách và tên độc giả (Dùng phương thức từ BaseBorrowService)
        String bookTitle = getBookTitle(borrow.getBookId());
        String readerName = getReaderName(borrow.getReaderId());

        // 7. Gửi Nhật ký hệ thống (Audit Log)
        auditMessagePort.sendBorrowEvent(
                "BOOK_REPORTED_LOST",
                borrow.getBorrowId(),
                String.format("%s đã báo mất cuốn sách '%s'. Phí thuê: %s, Tiền phạt: %s. TỔNG CỘNG CẦN THANH TOÁN: %s",
                        readerName,
                        bookTitle,
                        formatVND(result.rentalFee()),
                        formatVND(result.fineAmount()),
                        formatVND(result.totalAmount()))
        );

        // 8. KÍCH HOẠT THÔNG BÁO EMAIL (Hóa đơn đền bù)
        String readerEmail = readerRegistryPort.getReaderEmail(borrow.getReaderId());

        notificationPort.sendNotification(
                "LOST_BOOK_REPORT",
                readerEmail,
                Map.of(
                        "readerName", readerName,
                        "bookTitle", bookTitle,
                        "reportDate", command.reportDate().toString(),
                        "rentalFee", formatVND(result.rentalFee()),
                        "fineAmount", formatVND(result.fineAmount()),
                        "totalAmount", formatVND(result.totalAmount())
                )
        );

        return result;
    }
}