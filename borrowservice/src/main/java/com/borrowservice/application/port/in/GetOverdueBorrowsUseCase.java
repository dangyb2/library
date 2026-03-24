package com.borrowservice.application.port.in;

import com.borrowservice.application.dto.OverdueBorrowView;

import java.util.List;

public interface GetOverdueBorrowsUseCase {
    List<OverdueBorrowView> list();
}
