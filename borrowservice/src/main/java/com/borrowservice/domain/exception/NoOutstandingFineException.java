package com.borrowservice.domain.exception;

public class NoOutstandingFineException extends BorrowDomainException {
    public NoOutstandingFineException(String borrowId) {
        super("Borrow record " + borrowId + " does not have any outstanding fines to pay.");
    }
}