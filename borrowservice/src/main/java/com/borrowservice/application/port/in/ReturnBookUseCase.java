package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.ReturnedBorrowView;
import com.borrowservice.application.port.in.command.ReturnBookCommand;

public interface ReturnBookUseCase {
    ReturnedBorrowView returnBook(ReturnBookCommand command);
}
