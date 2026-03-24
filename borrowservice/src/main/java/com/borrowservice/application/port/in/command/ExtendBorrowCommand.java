package com.borrowservice.application.port.in.command;

import java.time.LocalDate;

public record ExtendBorrowCommand(String borrowId, LocalDate newDueDate) {
}
