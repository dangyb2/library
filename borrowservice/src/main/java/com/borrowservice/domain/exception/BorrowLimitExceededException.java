package com.borrowservice.domain.exception;

public class BorrowLimitExceededException extends BorrowDomainException {
    public BorrowLimitExceededException(String readerId, int maxLimit) {
        super("Reader " + readerId + " has reached the maximum allowed borrows (" + maxLimit + ").");
    }
}