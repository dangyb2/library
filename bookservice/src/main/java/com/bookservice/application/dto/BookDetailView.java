package com.bookservice.application.dto;

import com.bookservice.domain.model.Book;

import java.time.LocalDate;
import java.util.Objects;
import java.util.Set;

public record BookDetailView(
        String id,
        String title,
        String author,
        String description,
        String isbn,
        String shelfLocation,
        Integer publicationYear,
        LocalDate addedDate,
        Set<String> genres,
        Long totalStock,
        Long availableStock,
        Long lentOutCount
) {

    public static BookDetailView fromBook(Book book){
        Objects.requireNonNull(book, "Book cannot be null");

        return new BookDetailView(
                book.getId(),
                book.getTitle(),
                book.getAuthor(),
                book.getDescription(),
                book.getIsbn(),
                book.getShelfLocation(),
                book.getPublicationYear(),
                book.getAddedDate(),
                book.getGenres(),
                book.getTotalStock(),
                book.getAvailableStock(),
                book.getLentOutCount()
        );
    }
}