package com.borrowservice.application.port.in.command;

import java.time.LocalDate;

public record ReturnPreviewCommand(
        String borrowId,
        LocalDate returnDate
) {}