package com.borrowservice.application.service;

import com.borrowservice.application.dto.BorrowReceiptView;
import com.borrowservice.application.dto.ReaderEligibilityView;
import com.borrowservice.application.port.in.BorrowBookUseCase;
import com.borrowservice.application.port.in.command.BorrowBookCommand;
import com.borrowservice.application.port.out.AuditMessagePort;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.NotificationPort; // <-- 1. Nhập cổng thông báo
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.*;
import com.borrowservice.domain.model.Borrow;
import com.borrowservice.domain.model.PaymentStatus;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Map; // <-- 2. Nhập Map để xử lý dữ liệu thông báo
import java.util.Optional;

import static com.borrowservice.application.util.CurrencyFormatter.formatVND;


@Transactional
public class BorrowBookService extends BaseBorrowService implements BorrowBookUseCase {
    private static final int MAX_BORROW_LIMIT = 5; // Giới hạn mượn tối đa 5 cuốn

    private final BookBorrowRepository bookBorrowRepository;
    private final AuditMessagePort auditMessagePort;
    private final NotificationPort notificationPort; // <-- 3. Khai báo Port thông báo

    public BorrowBookService(BookBorrowRepository bookBorrowRepository,
                             ReaderRegistryPort readerRegistryPort,
                             BookCatalogPort bookCatalogPort,
                             AuditMessagePort auditMessagePort,
                             NotificationPort notificationPort) { // <-- 4. Tiêm (Inject) Port vào Constructor
        super(bookCatalogPort, readerRegistryPort);
        this.bookBorrowRepository = bookBorrowRepository;
        this.auditMessagePort = auditMessagePort;
        this.notificationPort = notificationPort; // <-- 5. Gán giá trị cho Port
    }

    @Override
    public BorrowReceiptView borrow(BorrowBookCommand command) {
        // Lấy thông tin cơ bản
        String bookTitle = getBookTitle(command.bookId());
        String readerName = getReaderName(command.readerId());

        // Kiểm tra điều kiện của độc giả
        ReaderEligibilityView eligibility = readerRegistryPort.getEligibilityDetails(command.readerId());

        if (!eligibility.eligible()) {
            throw new ReaderNotEligibleException(readerName, "Tài khoản không đủ điều kiện mượn sách.");
        }

        // Kiểm tra ngày hẹn trả so với thời hạn thẻ thành viên
        if (command.dueDate().isAfter(eligibility.membershipExpireAt())) {
            throw new InvalidDataException("Ngày hẹn trả của " + readerName + " không được vượt quá ngày hết hạn thẻ thành viên.");
        }

        // Kiểm tra sách có sẵn trong kho hay không
        if (!bookCatalogPort.isBookAvailable(command.bookId())) {
            throw new BookNotAvailableException(bookTitle);
        }

        // Kiểm tra các khoản phạt chưa thanh toán
        if (bookBorrowRepository.existsByReaderIdAndPaymentStatus(command.readerId(), PaymentStatus.UNPAID)) {
            throw new OutstandingFinesException(readerName);
        }

        // Kiểm tra xem độc giả đã mượn cuốn sách này mà chưa trả hay chưa
        Optional<Borrow> existingRecord = bookBorrowRepository.findByReaderIdAndBookIdAndStatus(
                command.readerId(),
                command.bookId(),
                com.borrowservice.domain.model.Status.BORROWED
        );

        if (existingRecord.isPresent()) {
            throw new BookAlreadyBorrowedException(readerName, bookTitle);
        }

        // Kiểm tra giới hạn số lượng sách đang mượn
        LocalDate borrowDate = LocalDate.now();
        long currentBorrowCount = bookBorrowRepository.countByReaderIdAndStatus(
                command.readerId(),
                com.borrowservice.domain.model.Status.BORROWED
        );

        if (currentBorrowCount >= MAX_BORROW_LIMIT) {
            throw new BorrowLimitExceededException(readerName, MAX_BORROW_LIMIT);
        }

        // Tạo bản ghi mượn sách mới
        Borrow borrow = new Borrow(
                command.readerId(),
                command.bookId(),
                borrowDate,
                command.dueDate(),
                command.conditionBorrow()
        );

        bookBorrowRepository.save(borrow);

        // Cập nhật giảm số lượng sách trong kho
        try {
            bookCatalogPort.decreaseBookStock(command.bookId());
        } catch (Exception e) {
            throw new BookNotAvailableException(bookTitle + " (Cập nhật kho thất bại)");
        }

        // 6. Ghi nhật ký hệ thống (Audit Log)
        auditMessagePort.sendBorrowEvent(
                "BOOK_BORROWED",
                borrow.getBorrowId(),
                String.format("%s đã mượn sách: %s. Phí thuê dự kiến: %s",
                        readerName, bookTitle, formatVND(borrow.getPrice()))
        );

        // 7. GỬI THÔNG BÁO QUA EMAIL!
        String readerEmail = readerRegistryPort.getReaderEmail(command.readerId());

        notificationPort.sendNotification(
                "BOOK_BORROWED",
                readerEmail,
                Map.of(
                        "readerName", readerName,
                        "bookTitle", bookTitle,
                        "borrowedAt", borrowDate.toString(),
                        "dueDate", command.dueDate().toString(),
                        "estimatedFee", formatVND(borrow.getPrice())
                )
        );

        // Trả về thông tin biên lai mượn sách
        return new BorrowReceiptView(
                borrow.getBorrowId(),
                borrow.getReaderId(),
                borrow.getBookId(),
                borrow.getBorrowDate(),
                borrow.getDueDate(),
                borrow.getConditionBorrow(),
                borrow.getPrice()
        );
    }
}