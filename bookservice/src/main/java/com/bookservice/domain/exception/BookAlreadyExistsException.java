package com.bookservice.domain.exception;

public class BookAlreadyExistsException extends RuntimeException {
    public BookAlreadyExistsException(String field, String value) {
        super(String.format("Book already exists with %s: '%s'", field, value));
    }
}