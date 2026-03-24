package com.bookservice.application.dto;

import com.bookservice.domain.model.Book;

import java.time.LocalDate;

public record TotalStockDecreaseView(
        String id,
        String title,
        String author,
        long totalStock,
        long availableStock,
        long copiesRemoved,
        String reason,
        LocalDate date
) {
    public static TotalStockDecreaseView fromBook(Book book, long copiesRemoved, String reason) {
        return new TotalStockDecreaseView(
                book.getId(),
                book.getTitle(),
                book.getAuthor(),
                book.getTotalStock(),
                book.getAvailableStock(),
                copiesRemoved,
                reason,
                LocalDate.now()
        );
    }
}