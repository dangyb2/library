package com.borrowservice.domain.exception;

public class InvalidDataException extends BorrowDomainException {
    public InvalidDataException(String message) {
        super(message);
    }
}