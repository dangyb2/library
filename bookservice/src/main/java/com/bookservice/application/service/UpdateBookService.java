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

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

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

        String newIsbn = command.isbn();
        if (newIsbn != null && !newIsbn.trim().isEmpty() && !Objects.equals(book.getIsbn(), newIsbn)) {
            if (repository.existsByIsbn(newIsbn)) {
                throw new DuplicateIsbnException(newIsbn);
            }
        }

        // 1. Calculate the "Diff" before updating
        List<String> changes = new ArrayList<>();

        if (!Objects.equals(book.getTitle(), command.title())) {
            changes.add(String.format("Tiêu đề ('%s' -> '%s')", book.getTitle(), command.title()));
        }
        if (!Objects.equals(book.getAuthor(), command.author())) {
            changes.add(String.format("Tác giả ('%s' -> '%s')", book.getAuthor(), command.author()));
        }
        if (!Objects.equals(book.getShelfLocation(), command.shelfLocation())) {
            changes.add(String.format("Vị trí ('%s' -> '%s')", book.getShelfLocation(), command.shelfLocation()));
        }
        // ... add other fields as necessary (description, genres, etc.)

        // 2. Perform the actual update
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

        // 3. Build and send the meaningful message
        String auditMessage;
        if (changes.isEmpty()) {
            auditMessage = "Đã lưu sách nhưng không có thay đổi dữ liệu nào.";
        } else {
            auditMessage = "Cập nhật sách thành công. Các thay đổi: " + String.join(", ", changes);
        }

        auditMessagePort.sendBookEvent(
                "BOOK_UPDATED",
                savedBook.getId(),
                auditMessage
        );

        return BookDetailView.fromBook(savedBook);
    }
}