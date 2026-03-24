package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.BorrowSummaryView;

import java.util.List;

public interface ListAllBorrowsUseCase {
    List<BorrowSummaryView> list();
}
