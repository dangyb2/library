package com.borrowservice.application.service;

import com.borrowservice.application.dto.BorrowSummaryView;
import com.borrowservice.application.port.in.ListAllBorrowsUseCase;
import com.borrowservice.application.port.out.BookBorrowRepository;
import com.borrowservice.application.port.out.BookCatalogPort;
import com.borrowservice.application.port.out.ReaderRegistryPort;
import com.borrowservice.domain.model.Borrow;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Transactional(readOnly = true)
public class ListAllBorrowsService implements ListAllBorrowsUseCase {

    private final BookBorrowRepository bookBorrowRepository;
    private final BookCatalogPort bookCatalogPort;
    private final ReaderRegistryPort readerRegistryPort;

    public ListAllBorrowsService(
            BookBorrowRepository bookBorrowRepository,
            BookCatalogPort bookCatalogPort,
            ReaderRegistryPort readerRegistryPort) {
        this.bookBorrowRepository = bookBorrowRepository;
        this.bookCatalogPort = bookCatalogPort;
        this.readerRegistryPort = readerRegistryPort;
    }

    @Override
    public List<BorrowSummaryView> list() {
        List<Borrow> borrows = bookBorrowRepository.findAll();

        // Quick exit if there are no borrows
        if (borrows.isEmpty()) {
            return Collections.emptyList();
        }

        // 1. Extract unique IDs using a Set
        Set<String> bookIds = borrows.stream()
                .map(Borrow::getBookId)
                .collect(Collectors.toSet());

        Set<String> readerIds = borrows.stream()
                .map(Borrow::getReaderId)
                .collect(Collectors.toSet());

        // 2. Batch fetch names (Only 2 network calls total!)
        Map<String, String> bookTitles = bookCatalogPort.getBookTitles(bookIds);
        Map<String, String> readerNames = readerRegistryPort.getReaderNames(readerIds);

        // 3. Build the views using Map lookups
        return borrows.stream()
                .map(borrow -> new BorrowSummaryView(
                        borrow.getBorrowId(),
                        borrow.getBookId(),
                        // Use getOrDefault as a fallback in case a book/reader was deleted
                        bookTitles.getOrDefault(borrow.getBookId(), "Unknown Book"),
                        borrow.getReaderId(),
                        readerNames.getOrDefault(borrow.getReaderId(), "Unknown Reader"),
                        borrow.getBorrowDate(),
                        borrow.getDueDate(),
                        borrow.getReturnDate(),
                        borrow.getStatus()
                ))
                .collect(Collectors.toList());
    }
}