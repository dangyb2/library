package com.readerservice.application.dto;

import com.readerservice.domain.model.Reader;
import com.readerservice.domain.model.Status;

import java.time.LocalDate;

public record ReaderView(
        String id,
        String name,
        String email,
        String phone,
        LocalDate membershipExpireAt,
        String status,
        String suspendReason
) {

    public static ReaderView from(Reader reader) {
        return new ReaderView(
                reader.getId(),
                reader.getName(),
                reader.getEmail().value(),
                reader.getPhone().value(),
                reader.getMembershipExpireAt(),
                reader.getStatus().name(),
                reader.getStatus() == Status.SUSPENDED
                        ? reader.getSuspendReason()
                        : null
        );
    }
}