package com.borrowservice.application.port.in;

public interface UndoCancelBorrowUseCase {
    void undoCancelBorrow(String borrowId);
}