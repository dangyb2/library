package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.BorrowDetailsView;
import com.borrowservice.application.port.in.command.UpdateBorrowCommand;

public interface UpdateBorrowUseCase {
    BorrowDetailsView update(UpdateBorrowCommand command);
}