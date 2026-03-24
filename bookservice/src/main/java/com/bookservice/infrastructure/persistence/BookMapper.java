package com.bookservice.infrastructure.persistence;

import com.bookservice.domain.model.Book;

public class BookMapper {

    public static BookEntity toEntity(Book book) {
        return new BookEntity(
                book.getId(),
                book.getTitle(),
                book.getAuthor(),
                book.getDescription(),
                book.getIsbn(),
                book.getShelfLocation(),
                book.getPublicationYear(),
                book.getAddedDate(),
                book.getTotalStock(),     // <-- Passed from Domain
                book.getAvailableStock(), // <-- Passed from Domain
                book.getGenres()
        );
    }

    public static Book toDomain(BookEntity entity) {
        return new Book(
                entity.getId(),
                entity.getAddedDate(),
                entity.getTitle(),
                entity.getAuthor(),
                entity.getDescription(),
                entity.getIsbn(),
                entity.getShelfLocation(),
                entity.getPublicationYear(),
                entity.getGenres(),
                entity.getTotalStock(),
                entity.getAvailableStock()
        );
    }
}