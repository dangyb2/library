package com.bookservice.domain.exception;

public class InsufficientStockException extends RuntimeException {

    public InsufficientStockException(String bookId, Long available, Long requested) {
        super(String.format(
                "Insufficient stock for book '%s'. Available: %d, Requested: %d",
                bookId, available, requested
        ));
    }

    public InsufficientStockException(String message) {
        super(message);
    }
}