package com.borrowservice.application.port.in;

public interface CancelBorrowUseCase {
    void cancelBorrow(String borrowId);
}