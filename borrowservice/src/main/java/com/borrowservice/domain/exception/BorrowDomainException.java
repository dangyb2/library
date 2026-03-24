package com.borrowservice.domain.exception;

public abstract class BorrowDomainException extends RuntimeException {
    public BorrowDomainException(String message) {
        super(message);
    }
}