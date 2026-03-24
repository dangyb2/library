package com.borrowservice.domain.exception;

public class BookNotAvailableException extends BorrowDomainException {
    public BookNotAvailableException(String title) {
        super("Book with title " + title + " is currently not available for borrowing.");
    }
}