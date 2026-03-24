package com.borrowservice.application.dto;

import java.math.BigDecimal;

// Đảm bảo các tên trường (rentalFee, fineAmount, totalAmount) khớp với cách gọi ở Service
public record LostReportResult(
        BigDecimal rentalFee,
        BigDecimal fineAmount,
        BigDecimal totalAmount
) {}