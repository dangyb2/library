package com.borrowservice.application.service;

import com.borrowservice.application.dto.OverdueBorrowView;
import com.borrowservice.application.port.in.GetOverdueBorrowsUseCase;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Transactional(readOnly=true)
public class GetOverdueBorrowsService implements GetOverdueBorrowsUseCase {
    private final BookBorrowRepository bookBorrowRepository;

    public GetOverdueBorrowsService(BookBorrowRepository bookBorrowRepository) {
        this.bookBorrowRepository = bookBorrowRepository;
    }

    @Override
    public List<OverdueBorrowView> list() {
        LocalDate today = LocalDate.now();

        List<Borrow> overdueBorrows = bookBorrowRepository.findOverdueBorrows(today);

        return overdueBorrows.stream()
                .map(borrow -> {
                    long daysOverdue = ChronoUnit.DAYS.between(borrow.getDueDate(), today);

                    return new OverdueBorrowView(
                            borrow.getBorrowId(),
                            borrow.getReaderId(),
                            borrow.getBookId(),
                            borrow.getDueDate(),
                            daysOverdue,
                            borrow.calculateEstimatedFine(today),
                            borrow.getPaymentStatus()
                    );
                })
                .collect(Collectors.toList());
    }
}