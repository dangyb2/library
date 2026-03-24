package com.borrowservice.domain.exception;

public class ExternalServiceUnavailableException extends BorrowDomainException {
    public ExternalServiceUnavailableException(String serviceName) {
        super("Unable to complete request. The " + serviceName + " is currently unavailable or returning errors.");
    }
}