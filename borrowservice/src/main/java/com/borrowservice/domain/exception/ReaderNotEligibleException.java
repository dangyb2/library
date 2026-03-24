package com.borrowservice.domain.exception;

public class ReaderNotEligibleException extends BorrowDomainException {
    public ReaderNotEligibleException(String readerName, String reason) {
        super("Reader '" + readerName + "' is not eligible to borrow books. Reason: " + reason);
    }
}