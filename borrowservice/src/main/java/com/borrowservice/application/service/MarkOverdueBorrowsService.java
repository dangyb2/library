package com.borrowservice.application.service;

import com.borrowservice.application.port.in.MarkOverdueBorrowsUseCase;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.NotificationPort;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static com.borrowservice.application.util.CurrencyFormatter.formatVND;

/**
 * Dịch vụ quét và đánh dấu các bản ghi mượn sách đã quá hạn.
 */
@Transactional
public class MarkOverdueBorrowsService extends BaseBorrowService implements MarkOverdueBorrowsUseCase {

    private final BookBorrowRepository bookBorrowRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort;
    private final ReaderRegistryPort readerRegistryPort; // Cần dùng để lấy email độc giả

    public MarkOverdueBorrowsService(BookBorrowRepository bookBorrowRepository,
                                     AuditMessagePort auditMessagePort,
                                     NotificationPort notificationPort,
                                     BookCatalogPort bookCatalogPort,
                                     ReaderRegistryPort readerRegistryPort) {
        super(bookCatalogPort, readerRegistryPort); // Truyền vào lớp cha BaseBorrowService
        this.bookBorrowRepository = bookBorrowRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort;
        this.readerRegistryPort = readerRegistryPort; // Lưu tham chiếu cục bộ
    }

    @Override
    public void markOverdue() {
        LocalDate today = LocalDate.now();
        // Tìm tất cả các bản ghi đã quá hạn tính đến ngày hôm nay
        List<Borrow> overdueBorrows = bookBorrowRepository.findOverdueBorrows(today);

        for (Borrow borrow : overdueBorrows) {
            // 1. Thay đổi trạng thái sang QUÁ HẠN và tính toán tiền phạt ban đầu
            borrow.markAsOverdue(today);
            bookBorrowRepository.save(borrow);

            // 2. Ghi nhật ký hệ thống (Audit Log)
            auditMessagePort.sendBorrowEvent(
                    "BORROW_OVERDUE",
                    borrow.getBorrowId(),
                    "Bản ghi mượn sách đã được đánh dấu là QUÁ HẠN. Tiền phạt ban đầu: " + formatVND(borrow.getFine())
            );

            // 3. Gửi thông báo Email (Thực hiện ngay trong vòng lặp)
            String readerEmail = readerRegistryPort.getReaderEmail(borrow.getReaderId());
            String bookTitle = getBookTitle(borrow.getBookId());

            notificationPort.sendNotification(
                    "BOOK_OVERDUE",
                    readerEmail,
                    Map.of(
                            "readerName", getReaderName(borrow.getReaderId()),
                            "bookTitle", bookTitle,
                            "dueDate", borrow.getDueDate().toString(),
                            "fineAmount", formatVND(borrow.getFine())
                    )
            );
        }

        // Thông báo kết quả thực hiện công việc định kỳ
        System.out.println("Công việc định kỳ hoàn tất: Đã đánh dấu " + overdueBorrows.size() + " bản ghi là QUÁ HẠN.");
    }
}