package com.bookservice.application.service;

import com.bookservice.application.dto.BookSummaryView;
import com.bookservice.application.port.in.FindBookByAuthorUseCase;
import com.bookservice.application.port.out.BookRepository;
import com.bookservice.domain.exception.InvalidBookDataException;
import com.bookservice.domain.model.Book;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Transactional(readOnly = true)
public class FindBookByAuthorService implements FindBookByAuthorUseCase {

    private final BookRepository repository;

    public FindBookByAuthorService(BookRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<BookSummaryView> findIgnoreCase(String author) {

        if (author == null || author.isBlank()) {
            throw new InvalidBookDataException("Tác giả không được để trống");
        }

        List<Book> books = repository.findByAuthorIgnoreCase(author);

        return books.stream()
                .map(BookSummaryView::fromBook)
                .toList();
    }
}