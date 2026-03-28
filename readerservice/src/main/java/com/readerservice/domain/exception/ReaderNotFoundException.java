package com.readerservice.domain.exception;

public class ReaderNotFoundException extends ReaderDomainException {

    public ReaderNotFoundException(String criteria) {
        super("Không tìm thấy độc giả với " + criteria);
    }
}
