package com.notificationservice.domain.exception;

import java.time.Instant;

public class InvalidDateRangeException extends RuntimeException {
    public InvalidDateRangeException(Instant fromDate, Instant toDate) {
        super("Invalid date range: fromDate (" + fromDate + ") must be before or equal to toDate (" + toDate + ")");
    }
}
