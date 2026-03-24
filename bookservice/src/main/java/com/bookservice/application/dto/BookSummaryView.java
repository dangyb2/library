package com.bookservice.application.dto;

import com.bookservice.domain.model.Book;

import java.util.Objects;
import java.util.Set;

public record BookSummaryView(
        String id,
        String title,
        String author,
        Integer publicationYear,
        Set<String> genres,
        Long totalStock,
        Long availableStock,
        Long lentOutCount
) {

    public static BookSummaryView fromBook(Book book) {
        Objects.requireNonNull(book, "Book cannot be null");

        return new BookSummaryView(
                book.getId(),
                book.getTitle(),
                book.getAuthor(),
                book.getPublicationYear(),
                book.getGenres(),
                book.getTotalStock(),
                book.getAvailableStock(),
                book.getLentOutCount()
        );
    }
}