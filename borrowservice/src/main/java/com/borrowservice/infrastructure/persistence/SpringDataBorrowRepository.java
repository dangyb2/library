package com.borrowservice.infrastructure.persistence;

import com.borrowservice.domain.model.PaymentStatus;
import com.borrowservice.domain.model.Status;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface SpringDataBorrowRepository extends JpaRepository<BorrowEntity, String> {
    List<BorrowEntity> findByReaderId(String readerId);
    List<BorrowEntity> findByReaderIdAndStatus(String readerId, Status status);
    List<BorrowEntity> findByStatusAndDueDateBefore(Status status, LocalDate currentDate);
    Optional<BorrowEntity> findByReaderIdAndBookIdAndStatus(String readerId, String bookId,Status status);
    boolean existsByReaderIdAndPaymentStatus(String readerId, PaymentStatus paymentStatus);
    long countByReaderIdAndStatus(String readerId, Status status);
    List<BorrowEntity> findByStatusAndDueDate(Status status, LocalDate dueDate);
    long countByBorrowDate(LocalDate date);
    long countByStatus(Status status);
    List<BorrowEntity> findByStatus(Status status);
}