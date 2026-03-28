package com.borrowservice.application.service;

import com.borrowservice.application.port.in.CheckActiveBorrowsUseCase;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.domain.model.PaymentStatus;
import com.borrowservice.domain.model.Status;
import org.springframework.transaction.annotation.Transactional;

@Transactional(readOnly = true)
public class CheckActiveBorrowsService implements CheckActiveBorrowsUseCase {

    private final BookBorrowRepository repository;

    public CheckActiveBorrowsService(BookBorrowRepository repository) {
        this.repository = repository;
    }

    @Override
    public boolean hasActiveBorrowsOrFines(String readerId) {
        // 1. Are they currently holding any books?
        long borrowedCount = repository.countByReaderIdAndStatus(readerId, Status.BORROWED);

        // 2. Do they have any overdue books?
        long overdueCount = repository.countByReaderIdAndStatus(readerId, Status.OVERDUE);

        // 3. Do they have any unpaid fines? (We know you have this method from your BorrowBookService!)
        boolean hasUnpaidFines = repository.existsByReaderIdAndPaymentStatus(readerId, PaymentStatus.UNPAID);

        return (borrowedCount > 0) || (overdueCount > 0) || hasUnpaidFines;
    }
}