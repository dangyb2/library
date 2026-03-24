package com.borrowservice.application.service;

import com.borrowservice.application.dto.BorrowDetailsView;
import com.borrowservice.application.port.in.GetBorrowDetailsUseCase;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.exception.BorrowRecordNotFoundException;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

@Transactional(readOnly=true)
public class GetBorrowDetailsService implements GetBorrowDetailsUseCase {

    private final BookBorrowRepository bookBorrowRepository;
    private final BookCatalogPort bookCatalogPort;
    private final ReaderRegistryPort readerRegistryPort;

    public GetBorrowDetailsService(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        this.bookBorrowRepository = bookBorrowRepository;
        this.bookCatalogPort = bookCatalogPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public BorrowDetailsView get(String borrowId) {
        Borrow borrow = bookBorrowRepository.findById(borrowId)
                .orElseThrow(() -> BorrowRecordNotFoundException.byRecordId(borrowId));

        String bookTitle = bookCatalogPort.getBookTitles(Set.of(borrow.getBookId()))
                .getOrDefault(borrow.getBookId(), "Unknown Book");

        String readerName = readerRegistryPort.getReaderNames(Set.of(borrow.getReaderId()))
                .getOrDefault(borrow.getReaderId(), "Unknown Reader");

        return new BorrowDetailsView(
                borrow.getBorrowId(),
                borrow.getReaderId(),
                readerName,
                borrow.getBookId(),
                bookTitle,
                borrow.getBorrowDate(),
                borrow.getDueDate(),
                borrow.getReturnDate(),
                borrow.getConditionBorrow(),
                borrow.getConditionReturn(),
                borrow.getStatus(),
                borrow.getPrice(),
                borrow.getFine(),
                borrow.getPaymentStatus()
        );
    }
}