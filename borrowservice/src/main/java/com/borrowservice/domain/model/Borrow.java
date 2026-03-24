package com.borrowservice.domain.model;

import com.borrowservice.domain.exception.InvalidBorrowStateException;
import com.borrowservice.domain.exception.InvalidDataException;
import com.borrowservice.domain.exception.FineAlreadyPaidException;
import com.borrowservice.domain.exception.BookNotOverdueException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

public class Borrow {
    public static final BigDecimal BORROW_PRICE = new BigDecimal("2000");
    public static final BigDecimal BASE_FINE = new BigDecimal("20000");
    public static final BigDecimal FINE_INCREASE = new BigDecimal("2500");

    private String borrowId;
    private String readerId;
    private String bookId;

    private LocalDate borrowDate;
    private LocalDate dueDate;
    private LocalDate returnDate;

    private BookCondition conditionBorrow;
    private BookCondition conditionReturn;

    private Status status;
    private BigDecimal price;
    private BigDecimal fine = BigDecimal.ZERO;
    private PaymentStatus paymentStatus = PaymentStatus.NONE;

    protected Borrow() {}

    public Borrow(String readerId,
                  String bookId,
                  LocalDate borrowDate,
                  LocalDate dueDate,
                  BookCondition conditionBorrow) {

        // 1. Kiểm tra sự tồn tại của ID Độc giả và ID Sách
        if (readerId == null || bookId == null) {
            throw new InvalidDataException("Mã độc giả (Reader ID) và Mã sách (Book ID) không được để trống");
        }

        if (borrowDate == null || dueDate == null) {
            throw new InvalidDataException("Các trường ngày tháng không được để trống");
        }

        if (dueDate.isBefore(borrowDate)) {
            throw new InvalidDataException("Ngày hẹn trả không được trước ngày mượn sách");
        }

        if (conditionBorrow == null || conditionBorrow == BookCondition.DAMAGED) {
            throw new InvalidDataException("Tình trạng sách khi mượn không được để trống hoặc không được ở trạng thái BỊ HỎNG (DAMAGED)");
        }
        validateId("READER-", readerId);
        validateId("BOOK-", bookId);

        this.borrowId = "BOR-" + UUID.randomUUID().toString();
        this.readerId = readerId;
        this.bookId = bookId;
        this.borrowDate = borrowDate;
        this.dueDate = dueDate;
        this.conditionBorrow = conditionBorrow;
        this.status = Status.BORROWED;
        this.price = calculateBorrowPrice(borrowDate, dueDate);
    }

    public static Borrow reconstitute(
            String borrowId, String readerId, String bookId,
            LocalDate borrowDate, LocalDate dueDate, LocalDate returnDate,
            BookCondition conditionBorrow, BookCondition conditionReturn,
            Status status, BigDecimal price, BigDecimal fine,
            PaymentStatus paymentStatus) {
        Borrow borrow = new Borrow();

        borrow.borrowId = borrowId;
        borrow.readerId = readerId;
        borrow.bookId = bookId;
        borrow.borrowDate = borrowDate;
        borrow.dueDate = dueDate;
        borrow.returnDate = returnDate;
        borrow.conditionBorrow = conditionBorrow;
        borrow.conditionReturn = conditionReturn;
        borrow.status = status;
        borrow.price = price;
        borrow.fine = fine;
        borrow.paymentStatus = paymentStatus;
        return borrow;
    }

    public void returnBook(LocalDate returnDate, BookCondition conditionReturn) {
        validateBorrowState(returnDate);
        this.price = calculateBorrowPrice(this.borrowDate, returnDate);
        if (conditionReturn == null) {
            // Kiểm tra bắt buộc phải có thông tin tình trạng sách lúc trả để đánh giá hư tổn (nếu có)
            throw new InvalidDataException("Tình trạng sách khi trả không được để trống");
        }
        BigDecimal totalFine = calculateOverdueFine(returnDate);

        if ((conditionBorrow == BookCondition.NEW || conditionBorrow == BookCondition.GOOD) &&
                conditionReturn == BookCondition.WORN) {
            BigDecimal halfFine = BASE_FINE.divide(new BigDecimal("2"), 2, RoundingMode.HALF_UP);
            totalFine = totalFine.add(halfFine);
        }

        if (conditionReturn == BookCondition.DAMAGED) {
            totalFine = totalFine.add(BASE_FINE);
        }

        this.fine = totalFine;
        this.returnDate = returnDate;
        this.conditionReturn = conditionReturn;
        this.status = Status.RETURNED;
        this.paymentStatus = PaymentStatus.UNPAID;
    }

    public void reportLost(LocalDate reportDate) {
        validateBorrowState(reportDate);

        this.price = calculateBorrowPrice(this.borrowDate, reportDate);

        this.fine = calculateOverdueFine(reportDate).add(BASE_FINE);

        this.returnDate = reportDate;
        this.status = Status.LOST;
        this.paymentStatus = PaymentStatus.UNPAID;

    }

    public void pay() {
        if (this.status != Status.RETURNED && this.status != Status.LOST) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "PAY");
        }

        if (this.paymentStatus == PaymentStatus.PAID) {
            throw new FineAlreadyPaidException(this.borrowId);
        }
        this.paymentStatus = PaymentStatus.PAID;
    }
    public BigDecimal extendBorrowTime(LocalDate newDueDate) {
        // 1. Chỉ cho phép gia hạn nếu sách đang ở trạng thái ĐANG MƯỢN
        if (this.status != Status.BORROWED) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "GIA_HAN_THOI_GIAN");
        }

        // 2. Kiểm tra tính hợp lệ của ngày mới
        if (newDueDate == null || !newDueDate.isAfter(this.dueDate)) {
            throw new InvalidDataException("Ngày hẹn trả mới phải sau ngày hẹn trả hiện tại");
        }

        this.dueDate = newDueDate;
        // Cập nhật lại giá thuê dựa trên thời gian mượn mới
        this.price = calculateBorrowPrice(this.borrowDate, this.dueDate);

        return BigDecimal.ZERO;
    }

    public void markAsOverdue(LocalDate currentDate) {
        // 1. Chỉ đánh dấu quá hạn cho những bản ghi đang mượn
        if (this.status != Status.BORROWED) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "DANH_DAU_QUA_HAN");
        }

        // 2. Kiểm tra xem thực tế đã quá hạn hay chưa
        if (!currentDate.isAfter(this.dueDate)) {
            throw new BookNotOverdueException(this.borrowId);
        }

        this.status = Status.OVERDUE;
        // Tính toán tiền phạt dựa trên số ngày trễ
        this.fine = calculateOverdueFine(currentDate);
        this.paymentStatus = PaymentStatus.UNPAID;
    }

    public void correctBorrowData(String readerId,
                                  String bookId,
                                  LocalDate borrowDate,
                                  LocalDate dueDate,
                                  BookCondition conditionBorrow) {
        // 1. Chặn hiệu chỉnh nếu bản ghi đã hoàn tất hoặc bị hủy (chỉ cho phép khi đang mượn)
        if (this.status != Status.BORROWED) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "HIEU_CHINH_DU_LIEU");
        }

        // 2. Kiểm tra tính toàn vẹn của dữ liệu ngày tháng
        if (borrowDate == null || dueDate == null) {
            throw new InvalidDataException("Ngày mượn và ngày hẹn trả không được để trống");
        }

        if (dueDate.isBefore(borrowDate)) {
            throw new InvalidDataException("Ngày hẹn trả không được trước ngày mượn");
        }

        // 3. Kiểm tra tình trạng sách (không được mượn sách đã hỏng)
        if (conditionBorrow == null || conditionBorrow == BookCondition.DAMAGED) {
            throw new InvalidDataException("Tình trạng sách khi mượn không hợp lệ hoặc sách đã bị hỏng");
        }

        // 4. Xác thực định dạng ID (giữ nguyên logic validateId của bạn)
        validateId("READER-", readerId);
        validateId("BOOK-", bookId);

        this.readerId = readerId;
        this.bookId = bookId;
        this.borrowDate = borrowDate;
        this.dueDate = dueDate;
        this.conditionBorrow = conditionBorrow;

        // Cập nhật lại giá tiền sau khi hiệu chỉnh ngày tháng
        this.price = calculateBorrowPrice(borrowDate, dueDate);
    }
    public void cancel() {
        if (this.status == Status.CANCELLED) {
            return;
        }
        if (this.status != Status.BORROWED) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "CANCEL");
        }
        this.status = Status.CANCELLED;
    }

    public void undoCancel() {
        if (this.status == Status.BORROWED) {
            return;
        }
        if (this.status != Status.CANCELLED) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "UNDO_CANCEL");
        }
        this.status = Status.BORROWED;
    }

    private BigDecimal calculateOverdueFine(LocalDate date) {
        if (date.isAfter(dueDate)) {
            long overdueDays = ChronoUnit.DAYS.between(dueDate, date);
            return FINE_INCREASE.multiply(BigDecimal.valueOf(overdueDays));
        }
        return BigDecimal.ZERO;
    }

    public BigDecimal calculateEstimatedFine(LocalDate calculationDate) {
        if (this.status != Status.BORROWED) {
            return this.fine;
        }
        return calculateOverdueFine(calculationDate);
    }

    public BigDecimal calculateBorrowPrice(LocalDate start, LocalDate end) {
        long days = ChronoUnit.DAYS.between(start, end);
        long billableDays = Math.max(1, days);
        return BORROW_PRICE.multiply(BigDecimal.valueOf(billableDays));
    }

    /**
     * Xác thực trạng thái hiện tại của bản ghi mượn sách trước khi thực hiện các thao tác tiếp theo.
     */
    private void validateBorrowState(LocalDate date) {
        // 1. Chỉ cho phép Trả hoặc Báo mất khi sách đang ở trạng thái ĐANG MƯỢN hoặc QUÁ HẠN
        if (this.status != Status.BORROWED && this.status != Status.OVERDUE) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "TRA_SACH/BAO_MAT");
        }

        // 2. Đảm bảo ngày thực hiện hành động không được rỗng hoặc trước ngày mượn
        if (date == null || date.isBefore(borrowDate)) {
            throw new InvalidDataException("Ngày thực hiện không được để trống hoặc diễn ra trước ngày mượn sách");
        }
    }

    /**
     * Kiểm tra định dạng ID (bao gồm tiền tố và chuỗi UUID).
     */
    private void validateId(String prefix, String id) {
        // Kiểm tra tiền tố bắt buộc (ví dụ: READER- hoặc BOOK-)
        if (id == null || !id.startsWith(prefix)) {
            throw new InvalidDataException("Định dạng mã không hợp lệ: thiếu tiền tố " + prefix);
        }

        try {
            // Tách chuỗi sau tiền tố để kiểm tra xem có phải UUID hợp lệ không
            UUID.fromString(id.substring(prefix.length()));
        } catch (IllegalArgumentException e) {
            throw new InvalidDataException("Mã không hợp lệ: chuỗi định danh sau tiền tố không đúng định dạng UUID");
        }
    }

    /**
     * Tạo một bản sao sâu (deep copy) của đối tượng Borrow hiện tại.
     * Thường dùng trong các trường hợp cần bảo vệ tính bất biến (immutability).
     */
    public Borrow copy() {
        return reconstitute(
                this.borrowId, this.readerId, this.bookId,
                this.borrowDate, this.dueDate, this.returnDate,
                this.conditionBorrow, this.conditionReturn,
                this.status, this.price, this.fine, this.paymentStatus
        );
    }

    /**
     * Đánh dấu đã tìm thấy sách sau khi từng bị báo mất.
     */
    public void markFound(LocalDate foundDate) {
        // Chỉ có thể khôi phục nếu trạng thái hiện tại đang là BỊ MẤT (LOST)
        if (this.status != Status.LOST) {
            throw new InvalidBorrowStateException(this.borrowId, this.status, "DANH_DAU_DA_TIM_THAY");
        }

        // Reverse the massive LOST fine, maybe just charge them the regular overdue fine
        this.fine = calculateOverdueFine(foundDate);
        this.returnDate = foundDate;
        this.status = Status.RETURNED;

        // Recalculate payment status
        this.paymentStatus = (this.fine.compareTo(BigDecimal.ZERO) > 0) ? PaymentStatus.UNPAID : PaymentStatus.NONE;
    }

    public String getBorrowId() {
        return borrowId;
    }

    public String getReaderId() {
        return readerId;
    }

    public String getBookId() {
        return bookId;
    }

    public LocalDate getBorrowDate() {
        return borrowDate;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public LocalDate getReturnDate() {
        return returnDate;
    }

    public BookCondition getConditionBorrow() {
        return conditionBorrow;
    }

    public BookCondition getConditionReturn() {
        return conditionReturn;
    }

    public Status getStatus() {
        return status;
    }

    public BigDecimal getFine() {
        return fine;
    }
    public BigDecimal getPrice() {
        return price;
    }
    public PaymentStatus getPaymentStatus() {
        return paymentStatus;
    }
}