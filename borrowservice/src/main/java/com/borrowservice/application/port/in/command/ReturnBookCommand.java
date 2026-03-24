package com.borrowservice.application.port.in.command;

import com.borrowservice.domain.model.BookCondition;

import java.time.LocalDate;

public record ReturnBookCommand(
        String borrowId,
        LocalDate returnDate,
        BookCondition conditionReturn) {
}
