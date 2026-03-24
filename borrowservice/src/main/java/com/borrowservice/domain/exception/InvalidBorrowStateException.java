package com.borrowservice.domain.exception;

import com.borrowservice.domain.model.Status;

public class InvalidBorrowStateException extends BorrowDomainException {

    public InvalidBorrowStateException(String borrowId, Status currentStatus, String attemptedAction) {
        super("Cannot perform action '" + attemptedAction + "' on borrow record " + borrowId +
                " because its current status is " + currentStatus + ".");
    }

    public InvalidBorrowStateException(String message) {
        super(message);
    }
}