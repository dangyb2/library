package com.borrowservice.application.service;

import com.borrowservice.application.dto.BorrowSummaryView;
import com.borrowservice.application.port.in.ListReaderBorrowsQuery;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.model.Borrow;
import com.borrowservice.domain.model.Status;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Transactional(readOnly=true)
public class ListReaderBorrowsService implements ListReaderBorrowsQuery {
    private final BookBorrowRepository bookBorrowRepository;
    private final BookCatalogPort bookCatalogPort;       // Added
    private final ReaderRegistryPort readerRegistryPort; // Added

    public ListReaderBorrowsService(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        this.bookBorrowRepository = bookBorrowRepository;
        this.bookCatalogPort = bookCatalogPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public List<BorrowSummaryView> list(String readerId, Status status) {
        List<Borrow> borrows;

        if (status == null) {
            borrows = bookBorrowRepository.findByReaderId(readerId);
        } else {
            borrows = bookBorrowRepository.findByReaderIdAndStatus(readerId, status);
        }

        if (borrows.isEmpty()) {
            return Collections.emptyList();
        }

        String readerName = readerRegistryPort.getReaderNames(Set.of(readerId))
                .getOrDefault(readerId, "Unknown Reader");

        Set<String> bookIds = borrows.stream()
                .map(Borrow::getBookId)
                .collect(Collectors.toSet());

        Map<String, String> bookTitles = bookCatalogPort.getBookTitles(bookIds);

        return borrows.stream()
                .map(borrow -> new BorrowSummaryView(
                        borrow.getBorrowId(),
                        borrow.getBookId(),
                        bookTitles.getOrDefault(borrow.getBookId(), "Unknown Book"), // Added
                        readerId,
                        readerName,
                        borrow.getBorrowDate(),
                        borrow.getDueDate(),
                        borrow.getReturnDate(),
                        borrow.getStatus()
                ))
                .collect(Collectors.toList());
    }
}