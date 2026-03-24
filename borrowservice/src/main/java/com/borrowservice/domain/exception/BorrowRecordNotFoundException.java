package com.borrowservice.domain.exception;

public class BorrowRecordNotFoundException extends RuntimeException {

    public BorrowRecordNotFoundException(String field, String value) {
        super(String.format("Borrow Record not found with %s: '%s'", field, value));
    }

    public static BorrowRecordNotFoundException byRecordId(String id) {
        return new BorrowRecordNotFoundException("Record ID", id);
    }


}