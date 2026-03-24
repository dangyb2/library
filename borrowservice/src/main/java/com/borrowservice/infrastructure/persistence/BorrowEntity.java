package com.borrowservice.infrastructure.persistence;

import com.borrowservice.domain.model.BookCondition;
import com.borrowservice.domain.model.PaymentStatus;
import com.borrowservice.domain.model.Status;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "borrow_records")
public class BorrowEntity {

    @Id
    @Column(name = "borrow_id", length = 50)
    private String borrowId;

    @Column(name = "reader_id", nullable = false, length = 50)
    private String readerId;

    @Column(name = "book_id", nullable = false, length = 50)
    private String bookId;

    @Column(name = "borrow_date", nullable = false)
    private LocalDate borrowDate;

    @Column(name = "due_date", nullable = false)
    private LocalDate dueDate;

    @Column(name = "return_date")
    private LocalDate returnDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "condition_borrow", nullable = false)
    private BookCondition conditionBorrow;

    @Enumerated(EnumType.STRING)
    @Column(name = "condition_return")
    private BookCondition conditionReturn;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private Status status;

    @Column(name = "price", precision = 10, scale = 2)
    private BigDecimal price;

    @Column(name = "fine", precision = 10, scale = 2)
    private BigDecimal fine;

    // FIX 1: Changed column name to payment_status
    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status", nullable = false)
    private PaymentStatus paymentStatus;

    protected BorrowEntity() {}

    // FIX 2: Added PaymentStatus to constructor
    public BorrowEntity(String borrowId, String readerId, String bookId, LocalDate borrowDate,
                        LocalDate dueDate, LocalDate returnDate, BookCondition conditionBorrow,
                        BookCondition conditionReturn, Status status, BigDecimal price, BigDecimal fine,
                        PaymentStatus paymentStatus) {
        this.borrowId = borrowId;
        this.readerId = readerId;
        this.bookId = bookId;
        this.borrowDate = borrowDate;
        this.dueDate = dueDate;
        this.returnDate = returnDate;
        this.conditionBorrow = conditionBorrow;
        this.conditionReturn = conditionReturn;
        this.status = status;
        this.price = price;
        this.fine = fine;
        this.paymentStatus = paymentStatus;
    }
    public String getBorrowId() {
        return borrowId;
    }

    public void setBorrowId(String borrowId) {
        this.borrowId = borrowId;
    }

    public String getReaderId() {
        return readerId;
    }

    public void setReaderId(String readerId) {
        this.readerId = readerId;
    }

    public String getBookId() {
        return bookId;
    }

    public void setBookId(String bookId) {
        this.bookId = bookId;
    }

    public LocalDate getBorrowDate() {
        return borrowDate;
    }

    public void setBorrowDate(LocalDate borrowDate) {
        this.borrowDate = borrowDate;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public void setDueDate(LocalDate dueDate) {
        this.dueDate = dueDate;
    }

    public LocalDate getReturnDate() {
        return returnDate;
    }

    public void setReturnDate(LocalDate returnDate) {
        this.returnDate = returnDate;
    }

    public BookCondition getConditionBorrow() {
        return conditionBorrow;
    }

    public void setConditionBorrow(BookCondition conditionBorrow) {
        this.conditionBorrow = conditionBorrow;
    }

    public BookCondition getConditionReturn() {
        return conditionReturn;
    }

    public void setConditionReturn(BookCondition conditionReturn) {
        this.conditionReturn = conditionReturn;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public BigDecimal getFine() {
        return fine;
    }

    public void setFine(BigDecimal fine) {
        this.fine = fine;
    }
    public PaymentStatus getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(PaymentStatus paymentStatus) {
        this.paymentStatus = paymentStatus;
    }
}