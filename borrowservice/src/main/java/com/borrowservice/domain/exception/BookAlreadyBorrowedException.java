package com.borrowservice.domain.exception;

public class BookAlreadyBorrowedException extends BorrowDomainException {
    public BookAlreadyBorrowedException(String readerName, String bookTitle) {
        super("Reader '" + readerName + "' has already borrowed '" + bookTitle + "' and has not returned it yet.");
    }
}