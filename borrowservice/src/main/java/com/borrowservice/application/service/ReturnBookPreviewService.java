package com.borrowservice.application.service;

import com.borrowservice.application.dto.ReturnPreviewResult;
import com.borrowservice.application.port.in.ReturnBookPreviewUseCase;
import com.borrowservice.application.port.in.command.ReturnPreviewCommand;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.temporal.ChronoUnit;

@Transactional(readOnly = true)
public class ReturnBookPreviewService extends BaseBorrowService implements ReturnBookPreviewUseCase {

    private final BookBorrowRepository bookBorrowRepository;

    public ReturnBookPreviewService(BookBorrowRepository bookBorrowRepository,
                                    BookCatalogPort bookCatalogPort,
                                    ReaderRegistryPort readerRegistryPort) {
        super(bookCatalogPort, readerRegistryPort);
        this.bookBorrowRepository = bookBorrowRepository;
    }

    @Override
    public ReturnPreviewResult preview(ReturnPreviewCommand command) {
        Borrow borrow = bookBorrowRepository.findById(command.borrowId())
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(command.borrowId()));

        String bookTitle = getBookTitle(borrow.getBookId());

        long daysBorrowed = ChronoUnit.DAYS.between(borrow.getBorrowDate(), command.returnDate());
        if (daysBorrowed < 0) daysBorrowed = 0;


        BigDecimal expectedPrice = borrow.calculateBorrowPrice(borrow.getBorrowDate(), command.returnDate());

        // 2. Calculate the fine using your existing method
        BigDecimal expectedFine = borrow.calculateEstimatedFine(command.returnDate());

        boolean isOverdue = command.returnDate().isAfter(borrow.getDueDate());

        return new ReturnPreviewResult(
                borrow.getBorrowId(),
                bookTitle,
                expectedPrice,
                expectedFine,
                isOverdue,
                daysBorrowed
        );
    }
}