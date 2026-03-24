package com.bookservice.application.port.in;

public interface RestoreLostBookUseCase {
    void restoreLost(String bookId);
}