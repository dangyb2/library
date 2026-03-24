package com.borrowservice.application.dto;

import com.borrowservice.domain.model.BookCondition;
import com.borrowservice.domain.model.Status;
import java.math.BigDecimal; // Đảm bảo dòng này có mặt
import java.time.LocalDate;

public record ReturnedBorrowView(
        String borrowId,
        String bookId,
        LocalDate returnDate,
        BookCondition conditionReturn,
        Status status,
        BigDecimal fine,
        BigDecimal finalPrice
) {
    public BigDecimal getTotalAmount() {
        BigDecimal f = (fine == null) ? BigDecimal.ZERO : fine;
        BigDecimal p = (finalPrice == null) ? BigDecimal.ZERO : finalPrice;
        return f.add(p);
    }
}