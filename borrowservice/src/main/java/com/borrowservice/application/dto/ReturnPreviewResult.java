package com.borrowservice.application.dto;

import java.math.BigDecimal;

public record ReturnPreviewResult(
        String borrowId,
        String bookTitle,
        BigDecimal currentPrice, // The cost of the rental itself
        BigDecimal fine,       // The late penalty (if any)
        boolean isOverdue,
        long daysBorrowed
) {

    public BigDecimal getTotalAmount() {
        if (currentPrice == null) return fine == null ? BigDecimal.ZERO : fine;
        if (fine == null) return currentPrice;

        return currentPrice.add(fine);
    }
}