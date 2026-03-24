package com.bookservice.domain.exception;

public class InvalidIsbnException extends RuntimeException {
    public InvalidIsbnException(String isbn) {
        super("Invalid ISBN: " + isbn);
    }
}