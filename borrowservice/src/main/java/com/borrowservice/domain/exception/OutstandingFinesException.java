package com.borrowservice.domain.exception;

public class OutstandingFinesException extends BorrowDomainException {
    public OutstandingFinesException(String readerName) {
        super("Reader '" + readerName + "' cannot borrow books because they have unpaid fines.");
    }
}