package com.bookservice.application.port.in.command;

public record DecreaseTotalStockCommand(
        long amount,
        String reason
) {
    public DecreaseTotalStockCommand {
        if (amount <= 0) {
            throw new IllegalArgumentException("Amount must be greater than zero");
        }
        if (reason == null || reason.isBlank()) {
            throw new IllegalArgumentException("Reason must be provided");
        }
    }
}