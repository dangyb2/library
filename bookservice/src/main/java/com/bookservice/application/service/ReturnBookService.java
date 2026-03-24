package com.bookservice.application.service;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.ReturnBookUseCase;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

@Transactional
public class ReturnBookService implements ReturnBookUseCase {

    private final BookRepository repository;
    private final AuditMessagePort auditMessagePort;

    public ReturnBookService(BookRepository repository,
                             AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public BookDetailView returnBook(String id) {

        Book book = repository.findById(id)
                .orElseThrow(() -> new BookNotFoundException("id", id));


        // Increase available copies on the shelf
        book.increaseAvailableStock(1L);

        Book savedBook = repository.save(book);
        auditMessagePort.sendBookEvent(
                "BOOK_RETURNED_TO_STOCK",
                savedBook.getId(),
                "Sách đã được hoàn trả về kho: " + savedBook.getTitle()
        );

        return BookDetailView.fromBook(savedBook);
    }
}