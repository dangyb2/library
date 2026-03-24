package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.BorrowSummaryView;
import com.borrowservice.domain.model.Status;

import java.util.List;

public interface ListReaderBorrowsQuery {
    List<BorrowSummaryView> list(String readerId, Status status);
}
