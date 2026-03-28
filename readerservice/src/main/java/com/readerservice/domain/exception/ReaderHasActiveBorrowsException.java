package com.readerservice.domain.exception;

public class ReaderHasActiveBorrowsException extends RuntimeException {
    public ReaderHasActiveBorrowsException(String name) {
        super("Không thể xóa: Độc giả " + name + " hiện đang mượn sách hoặc chưa nộp phạt.");
    }
}