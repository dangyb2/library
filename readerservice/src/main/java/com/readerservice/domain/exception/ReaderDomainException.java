package com.readerservice.domain.exception;

public abstract class ReaderDomainException extends RuntimeException {
    protected ReaderDomainException(String message) {
        super(message);
    }
}
