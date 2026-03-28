package com.borrowservice.application.port.in;

public interface CheckActiveBorrowsUseCase {
    boolean hasActiveBorrowsOrFines(String readerId);
}