package com.borrowservice.domain.exception;

public class BookNotOverdueException extends BorrowDomainException {
    public BookNotOverdueException(String borrowId) {
        super("Cannot mark borrow record " + borrowId + " as overdue. It is not past its due date yet.");
    }
}