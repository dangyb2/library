package com.borrowservice.application.port.in.command;

import java.time.LocalDate;

public record FoundLostBookCommand(String borrowId, LocalDate foundDate) {
}