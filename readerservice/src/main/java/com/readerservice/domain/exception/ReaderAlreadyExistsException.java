package com.readerservice.domain.exception;

public class ReaderAlreadyExistsException extends RuntimeException {

    public ReaderAlreadyExistsException(String message) {
        super(message);
    }

    public static ReaderAlreadyExistsException forEmail(String email) {
        return new ReaderAlreadyExistsException("Reader with email " + email + " already exists");
    }

    public static ReaderAlreadyExistsException forPhone(String phone) {
        return new ReaderAlreadyExistsException("Reader with phone " + phone + " already exists");
    }
}
