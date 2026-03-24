package com.bookservice.domain.exception;

public class BookCurrentlyBorrowedException extends RuntimeException {

    public BookCurrentlyBorrowedException(String bookId) {
        super(String.format("Cannot delete book '%s'. There are currently copies checked out by readers.", bookId));
    }
}