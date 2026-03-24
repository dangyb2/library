package com.bookservice.domain.exception;

public class BookNotFoundException extends RuntimeException {

    public BookNotFoundException(String field, String value) {
        super(String.format("Book not found with %s: '%s'", field, value));
    }

    public BookNotFoundException(String bookId) {
    }

    public static BookNotFoundException byId(String id) {
        return new BookNotFoundException("id", id);
    }

    public static BookNotFoundException byIsbn(String isbn) {
        return new BookNotFoundException("isbn", isbn);
    }

}