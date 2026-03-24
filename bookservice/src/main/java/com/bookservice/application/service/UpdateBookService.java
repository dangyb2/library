package com.bookservice.application.service;

import com.bookservice.application.dto.BookDetailView;
import com.bookservice.application.port.in.UpdateBookUseCase;
import com.bookservice.application.port.in.command.UpdateBookCommand;
import com.bookservice.application.port.out.AuditMessagePort;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.BookNotFoundException;
import com.bookservice.domain.exception.DuplicateIsbnException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;
@Transactional
public class UpdateBookService implements UpdateBookUseCase {

    private final BookRepository repository;
    private final AuditMessagePort auditMessagePort;

    public UpdateBookService(BookRepository repository, AuditMessagePort auditMessagePort) {
        this.repository = repository;
        this.auditMessagePort = auditMessagePort;
    }

    @Override
    public BookDetailView update(String id, UpdateBookCommand command) {
        Book book = repository.findById(id)
                .orElseThrow(() -> new BookNotFoundException("id", id));

        if (repository.existsByIsbn(command.isbn())
                && !book.getIsbn().equals(command.isbn())) {
            throw new DuplicateIsbnException(command.isbn());
        }
        book.updateDetails(
                command.title(),
                command.author(),
                command.description(),
                command.isbn(),
                command.shelfLocation(),
                command.publicationYear(),
                command.genres()
        );

        Book savedBook = repository.save(book);

        auditMessagePort.sendBookEvent(
                "BOOK_UPDATED",
                savedBook.getId(),
                "Sách đã được cập nhật với tiêu đề: " + savedBook.getTitle()
        );
        return BookDetailView.fromBook(savedBook);
    }
}