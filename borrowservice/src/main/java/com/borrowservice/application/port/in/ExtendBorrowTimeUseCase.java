package com.borrowservice.application.port.in;


import com.borrowservice.application.dto.ExtendBorrowResultView;
import com.borrowservice.application.port.in.command.ExtendBorrowCommand;


public interface ExtendBorrowTimeUseCase {
    ExtendBorrowResultView extend(ExtendBorrowCommand command);
}
