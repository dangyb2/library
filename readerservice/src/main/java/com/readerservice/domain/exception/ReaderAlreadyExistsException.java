package com.readerservice.domain.exception;

public class ReaderAlreadyExistsException extends ReaderDomainException {

    public ReaderAlreadyExistsException(String message) {
        super(message);
    }

    public static ReaderAlreadyExistsException forEmail(String email) {
        return new ReaderAlreadyExistsException("Đã tồn tại độc giả với email: " + email);
    }

    public static ReaderAlreadyExistsException forPhone(String phone) {
        return new ReaderAlreadyExistsException("Đã tồn tại độc giả với số điện thoại: " + phone);
    }
}
