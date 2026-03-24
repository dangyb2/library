package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.BorrowDetailsView;

public interface GetBorrowDetailsUseCase {
    BorrowDetailsView get(String borrowId);
}
