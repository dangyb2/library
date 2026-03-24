package com.borrowservice.application.port.out;

import com.borrowservice.domain.model.Borrow;
import com.borrowservice.domain.model.PaymentStatus;
import com.borrowservice.domain.model.Status;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface BookBorrowRepository {
    Borrow save(Borrow borrow);
    Optional<Borrow> findById(String borrowId);
    List<Borrow> findAll();
    List<Borrow> findOverdueBorrows(LocalDate currentDate);
    List<Borrow> findByReaderId(String readerId);
    List<Borrow> findByReaderIdAndStatus(String readerId, Status status);
    Optional<Borrow> findByReaderIdAndBookIdAndStatus(String readerId, String bookId, Status status);
    boolean existsByReaderIdAndPaymentStatus(String readerId, PaymentStatus paymentStatus);
    long countByReaderIdAndStatus(String readerId, Status status);
}
