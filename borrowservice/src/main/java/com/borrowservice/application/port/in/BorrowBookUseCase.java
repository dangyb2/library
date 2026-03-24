package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.BorrowReceiptView;
import com.borrowservice.application.port.in.command.BorrowBookCommand;

public interface BorrowBookUseCase {
    BorrowReceiptView borrow(BorrowBookCommand command);
}
