package com.readerservice.application.port.out;

public interface CheckReaderBorrowStatusPort {
    boolean hasActiveBorrowsOrFines(String readerId);
}