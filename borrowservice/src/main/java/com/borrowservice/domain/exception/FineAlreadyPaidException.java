
package com.borrowservice.domain.exception;

public class FineAlreadyPaidException extends BorrowDomainException {
    public FineAlreadyPaidException(String borrowId) {
        super("The fine for borrow record " + borrowId + " has already been paid.");
    }
}